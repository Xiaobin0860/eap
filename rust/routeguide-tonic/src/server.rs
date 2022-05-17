use anyhow::Result;
use futures_core::Stream;
use std::pin::Pin;
use std::sync::Arc;
use tokio_stream::wrappers::ReceiverStream;
use tonic::{transport::Server, Streaming};
use tonic::{Request, Response, Status};
use tracing::debug;

use routeguide_tonic::{load_routeguide_data, RouteGuide, RouteGuideServer};
use routeguide_tonic::{Feature, Point, Rectangle, RouteNote, RouteSummary};

#[derive(Debug)]
struct RouteGuideService {
    features: Arc<Vec<Feature>>,
}

#[tonic::async_trait]
impl RouteGuide for RouteGuideService {
    async fn get_feature(&self, req: Request<Point>) -> Result<Response<Feature>, Status> {
        debug!("get_feature {req:?}");

        for feature in &self.features[..] {
            if feature.location.as_ref() == Some(req.get_ref()) {
                return Ok(Response::new(feature.clone()));
            }
        }

        Ok(Response::new(Feature::default()))
    }

    type ListFeaturesStream = ReceiverStream<Result<Feature, Status>>;
    async fn list_features(
        &self,
        _req: Request<Rectangle>,
    ) -> Result<Response<Self::ListFeaturesStream>, Status> {
        todo!()
    }

    async fn record_route(
        &self,
        _req: Request<Streaming<Point>>,
    ) -> Result<Response<RouteSummary>, Status> {
        todo!()
    }

    type RouteChatStream = Pin<Box<dyn Stream<Item = Result<RouteNote, Status>> + Send>>;
    async fn route_chat(
        &self,
        _req: tonic::Request<Streaming<RouteNote>>,
    ) -> Result<tonic::Response<Self::RouteChatStream>, tonic::Status> {
        todo!()
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();

    let addr = "[::1]:50052".parse()?;

    let route_guide = RouteGuideService {
        features: Arc::new(load_routeguide_data()),
    };

    let svc = RouteGuideServer::new(route_guide);

    Server::builder().add_service(svc).serve(addr).await?;

    Ok(())
}
