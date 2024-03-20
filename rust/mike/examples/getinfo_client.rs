use futures::{SinkExt, StreamExt};
use tokio::net::TcpStream;
use tokio_util::codec::{Framed, LengthDelimitedCodec};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    println!("{:?}", std::env::current_dir());
    let stream = TcpStream::connect("127.0.0.1:8888").await?;
    println!("Connected to server");

    let mut framed_stream = Framed::new(stream, LengthDelimitedCodec::new());

    framed_stream.send("getinfo".into()).await?;

    if let Some(msg) = framed_stream.next().await {
        match msg {
            Ok(msg) => {
                let msg = String::from_utf8(msg.to_vec())?;
                println!("{msg}");
            }
            Err(e) => {
                eprintln!("{e:?}");
            }
        }
    }

    Ok(())
}
