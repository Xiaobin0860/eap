use rltk::{GameState, Rltk, RltkBuilder, RGB};
use specs::prelude::*;
use specs_derive::Component;

type COL = (u8, u8, u8);

fn main() -> rltk::BError {
    let context = RltkBuilder::simple80x50()
        .with_title("Roguelit Tutorial")
        .build()?;

    let mut gs = State::new();
    gs.ecs.register::<Position>();
    gs.ecs.register::<Renderable>();
    gs.ecs.register::<LeftMover>();

    gs.ecs
        .create_entity()
        .with(Position::new(40, 25))
        .with(Renderable::new('@', rltk::YELLOW, rltk::BLACK))
        .build();

    for i in 0..10 {
        gs.ecs
            .create_entity()
            .with(Position::new(i * 7, 20))
            .with(Renderable::new('☺', rltk::RED, rltk::BLACK))
            .with(LeftMover::new())
            .build();
    }

    rltk::main_loop(context, gs)
}

#[derive(Debug, Component)]
struct Position {
    x: i32,
    y: i32,
}

impl Position {
    fn new(x: i32, y: i32) -> Self {
        Self { x, y }
    }
}

#[derive(Debug, Component)]
struct Renderable {
    glyph: rltk::FontCharType,
    fg: RGB,
    bg: RGB,
}

impl Renderable {
    fn new(c: char, fg: COL, bg: COL) -> Self {
        Self {
            glyph: rltk::to_cp437(c),
            fg: RGB::named(fg),
            bg: RGB::named(bg),
        }
    }
}

#[derive(Component)]
struct LeftMover {}

impl LeftMover {
    fn new() -> Self {
        Self {}
    }
}

struct LeftWalker {}

impl LeftWalker {
    fn new() -> Self {
        Self {}
    }
}
impl<'a> System<'a> for LeftWalker {
    type SystemData = (ReadStorage<'a, LeftMover>, WriteStorage<'a, Position>);

    fn run(&mut self, (lefty, mut pos): Self::SystemData) {
        for (_, pos) in (&lefty, &mut pos).join() {
            pos.x -= 1;
            if pos.x < 0 {
                pos.x = 79;
            }
        }
    }
}

struct State {
    ecs: World,
}

impl State {
    fn new() -> Self {
        Self { ecs: World::new() }
    }

    fn run_systems(&mut self) {
        let mut lw = LeftWalker::new();
        lw.run_now(&self.ecs);
        self.ecs.maintain();
    }
}

impl GameState for State {
    fn tick(&mut self, ctx: &mut Rltk) {
        ctx.cls();

        self.run_systems();

        let positions = self.ecs.read_storage::<Position>();
        let renderables = self.ecs.read_storage::<Renderable>();

        for (pos, render) in (&positions, &renderables).join() {
            ctx.set(pos.x, pos.y, render.fg, render.bg, render.glyph);
        }
    }
}
