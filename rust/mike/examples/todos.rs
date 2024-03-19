use std::{ops::Deref, sync::Arc};

use anyhow::{Context, Result};
use axum::{
    debug_handler,
    extract::{Path, Query, State},
    http::StatusCode,
    response::{IntoResponse, Response},
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sqlx::mysql::MySqlPool;
use time::{format_description, UtcOffset};
use tokio::net::TcpListener;
use tower_http::trace::TraceLayer;
use tracing::{info, level_filters::LevelFilter, trace};
use tracing_subscriber::{fmt::time::OffsetTime, EnvFilter};

#[derive(Debug)]
struct AppCfg {
    bind: String,
    sql: String,
    log: String,
}

impl AppCfg {
    fn new() -> Self {
        Self {
            bind: "127.0.0.1:8889".into(),
            sql: "mysql://root:123456@192.168.0.15:3306/todos".into(),
            log: "todo=trace,tower_http=debug".into(),
        }
    }
}

struct TodoState {
    pool: MySqlPool,
}

#[derive(Clone)]
struct TodoApp(Arc<TodoState>);
impl Deref for TodoApp {
    type Target = TodoState;
    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl TodoApp {
    async fn new(cfg: &AppCfg) -> Result<Self> {
        let pool = MySqlPool::connect(&cfg.sql).await?;
        let state = TodoState { pool };
        Ok(Self(Arc::new(state)))
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let cfg = AppCfg::new();

    let timer = OffsetTime::new(
        UtcOffset::current_local_offset().unwrap_or(UtcOffset::from_hms(8, 0, 0)?),
        format_description::parse(
            "[year]-[month]-[day] [hour]:[minute]:[second].[subsecond digits:3]",
        )?,
    );
    let filter = EnvFilter::builder()
        .with_default_directive(LevelFilter::INFO.into())
        .parse(&cfg.log)?;
    tracing_subscriber::fmt()
        .with_file(true)
        .with_line_number(true)
        .with_thread_ids(true)
        .with_timer(timer)
        .with_env_filter(filter)
        .init();

    info!("start app {cfg:?}");

    trace!("create app state");
    let state = TodoApp::new(&cfg).await?;
    trace!("create listener");
    let listener = TcpListener::bind(&cfg.bind).await?;

    let router = Router::new()
        .route("/todos", get(todos_list))
        .route("/todo/new", post(todo_create))
        .route("/todo/update", post(todo_update))
        .route("/todo/delete/:id", post(todo_delete))
        .route("/todo/get/:id", get(todo_get))
        .with_state(state)
        .layer(TraceLayer::new_for_http());

    axum::serve(listener, router.into_make_service()).await?;

    Ok(())
}

#[derive(Debug, Deserialize, Default)]
struct Pagination {
    offset: Option<u32>,
    limit: Option<u32>,
}

pub struct AppError(anyhow::Error);
impl<E> From<E> for AppError
where
    E: Into<anyhow::Error>,
{
    fn from(e: E) -> Self {
        Self(e.into())
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Something went wrong: {}", self.0),
        )
            .into_response()
    }
}

pub type AppResult<T> = std::result::Result<T, AppError>;

pub struct JsonRes(Json<Res>);

impl<T> From<T> for JsonRes
where
    T: Serialize,
{
    fn from(value: T) -> Self {
        Self(Json(Res::from_data(value)))
    }
}

impl IntoResponse for JsonRes {
    fn into_response(self) -> Response {
        self.0.into_response()
    }
}

#[debug_handler]
async fn todos_list(
    State(app): State<TodoApp>,
    pagination: Option<Query<Pagination>>,
) -> AppResult<JsonRes> {
    let pagination = pagination.unwrap_or_default();
    let offset = pagination.offset.unwrap_or(0);
    let limit = pagination.limit.unwrap_or(100);
    let todos = app.todos_list(offset, limit).await?;
    Ok(todos.into())
}

#[derive(Debug, Deserialize)]
struct TodoCreate {
    des: String,
}

async fn todo_create(State(app): State<TodoApp>, Json(c): Json<TodoCreate>) -> AppResult<JsonRes> {
    let id = app.todo_create(&c.des).await?;
    Ok(id.into())
}

async fn todo_update() -> AppResult<JsonRes> {
    todo!()
}

async fn todo_delete(State(app): State<TodoApp>, Path(id): Path<u64>) -> AppResult<JsonRes> {
    app.todo_delete(id).await?;
    Ok(0.into())
}

async fn todo_get(State(app): State<TodoApp>, Path(id): Path<u64>) -> AppResult<JsonRes> {
    Ok(app.todo_get(id).await?.into())
}

#[derive(Debug, Deserialize)]
pub struct Req {
    pub cmd: i32,
    pub data: Option<Value>,
}

#[derive(Debug, Serialize)]
pub struct Res {
    pub code: i32,
    pub data: Option<Value>,
}

impl Res {
    pub fn from_code(code: i32) -> Self {
        Self { code, data: None }
    }

    pub fn from_data<T>(data: T) -> Self
    where
        T: Serialize,
    {
        let data = serde_json::to_value(data).context("from_data").unwrap();
        Self {
            code: 0,
            data: Some(data),
        }
    }
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Todo {
    pub id: u64,
    pub des: String,
    pub done: u8,
}

impl TodoApp {
    async fn todos_list(&self, offset: u32, limit: u32) -> Result<Vec<Todo>> {
        trace!("todos_list offset: {offset}, limit: {limit}");
        let todos = sqlx::query_as!(
            Todo,
            r#"SELECT id, des, done FROM todo LIMIT ?, ?"#,
            offset,
            limit
        )
        .fetch_all(&self.pool)
        .await?;
        Ok(todos)
    }

    async fn todo_create(&self, des: &str) -> Result<u64> {
        trace!("todo_create des: {des}");
        let res = sqlx::query!(r#"INSERT INTO todo (des, done) VALUES (?, 0)"#, des)
            .execute(&self.pool)
            .await?;
        Ok(res.last_insert_id())
    }

    async fn todo_delete(&self, id: u64) -> Result<()> {
        trace!("todo_delete id: {id}");
        sqlx::query!(r#"DELETE FROM todo WHERE id = ?"#, id)
            .execute(&self.pool)
            .await?;
        Ok(())
    }

    async fn todo_get(&self, id: u64) -> Result<Todo> {
        trace!("todo_get id: {id}");
        let todo = sqlx::query_as!(Todo, r#"SELECT id, des, done FROM todo WHERE id = ?"#, id)
            .fetch_one(&self.pool)
            .await?;
        Ok(todo)
    }
}
