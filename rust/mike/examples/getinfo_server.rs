use std::time::SystemTime;

use chrono::{DateTime, Local};
use futures::{SinkExt, StreamExt};
use tokio::net::TcpListener;
use tokio_util::codec::{Framed, LengthDelimitedCodec};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let listener = TcpListener::bind("127.0.0.1:8888").await?;
    println!("Listening on {}", listener.local_addr()?);
    while let Ok((socket, addr)) = listener.accept().await {
        println!("Accepted connection from {}", addr);
        tokio::spawn(async move {
            let mut framed_stream = Framed::new(socket, LengthDelimitedCodec::new());
            while let Some(msg) = framed_stream.next().await {
                match msg {
                    Ok(msg) => {
                        println!("Received message from {addr}, {:?}", msg);
                        let msg = String::from_utf8(msg.to_vec())?;
                        match msg.as_str() {
                            "getinfo" => {
                                let now: DateTime<Local> = SystemTime::now().into();
                                let res = format!("version: 0.1.0\nauthor: Mike\nnow: {now:?}\n");
                                framed_stream.send(res.into()).await?;
                            }
                            _ => {
                                framed_stream.send("unknown command\n".into()).await?;
                            }
                        }
                    }
                    Err(e) => {
                        eprintln!("Failed to read from {addr}, {e:?}");
                        break;
                    }
                }
            }
            anyhow::Ok(())
        });
    }
    Ok(())
}
