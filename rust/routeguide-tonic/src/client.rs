use anyhow::Result;
use futures::stream;
use rand::prelude::ThreadRng;
use rand::Rng;
use std::time::Duration;
use tokio::time;
use tonic::transport::Channel;
use tonic::Request;
use tracing::debug;

use routeguide_tonic::RouteGuideClient;
use routeguide_tonic::{Point, Rectangle, RouteNote};

async fn print_features(client: &mut RouteGuideClient<Channel>) -> Result<()> {
    let rectangle = Rectangle {
        lo: Some(Point {
            latitude: 400_000_000,
            longitude: -750_000_000,
        }),
        hi: Some(Point {
            latitude: 420_000_000,
            longitude: -730_000_000,
        }),
    };

    let mut stream = client
        .list_features(Request::new(rectangle))
        .await?
        .into_inner();

    while let Some(feature) = stream.message().await? {
        println!("NOTE = {feature:?}");
    }

    Ok(())
}

async fn run_record_route(client: &mut RouteGuideClient<Channel>) -> Result<()> {
    let mut rng = rand::thread_rng();
    let point_count = rng.gen_range(10..100);

    let mut points = Vec::with_capacity(point_count);
    for _ in 0..point_count {
        points.push(random_point(&mut rng));
    }

    debug!("Traversing {} points", points.len());
    let req = Request::new(stream::iter(points));

    match client.record_route(req).await {
        Ok(res) => println!("SUMMARY: {:?}", res.into_inner()),
        Err(err) => println!("ERROR: {:?}", err),
    }

    Ok(())
}

async fn run_route_chat(client: &mut RouteGuideClient<Channel>) -> Result<()> {
    let start = time::Instant::now();

    let outbound = async_stream::stream! {
        let mut interval = time::interval(Duration::from_secs(1));

        loop {
            let time = interval.tick().await;
            let elapsed = time.duration_since(start);
            let note = RouteNote {
                location: Some(Point{
                    latitude: 409146138 + elapsed.as_secs() as i32,
                    longitude: -746188906,
                }),
                message: format!("{:?}", elapsed),
            };
            yield note;
        }
    };

    let res = client.route_chat(Request::new(outbound)).await?;
    let mut inbound = res.into_inner();

    while let Some(note) = inbound.message().await? {
        println!("NOTE = {note:?}");
    }

    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();

    let mut client = RouteGuideClient::connect("http://[::1]:50052").await?;

    println!("*** SIMPLE RPC ***");
    let response = client
        .get_feature(Request::new(Point {
            latitude: 409_146_138,
            longitude: -746_188_906,
        }))
        .await?;
    println!("RESPONSE = {:?}", response);

    println!("\n*** SERVER STREAMING ***");
    print_features(&mut client).await?;

    println!("\n*** CLIENT STREAMING ***");
    run_record_route(&mut client).await?;

    println!("\n*** BIDIRECTIONAL STREAMING ***");
    run_route_chat(&mut client).await?;

    Ok(())
}

fn random_point(rng: &mut ThreadRng) -> Point {
    let latitude = (rng.gen_range(0..180) - 90) * 10_000_000;
    let longitude = (rng.gen_range(0..360) - 180) * 10_000_000;
    Point {
        latitude,
        longitude,
    }
}
