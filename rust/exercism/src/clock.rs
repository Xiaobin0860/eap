use std::fmt::Display;

#[derive(Debug, PartialEq)]
pub struct Clock {
    hours: i32,
    minutes: i32,
}

impl Clock {
    pub fn new(hours: i32, minutes: i32) -> Self {
        // let mut hours = hours + minutes / 60;
        // let mut minutes = minutes % 60;
        // if minutes < 0 {
        //     hours -= 1;
        //     minutes += 60;
        // }
        // hours %= 24;
        // if hours < 0 {
        //     hours += 24;
        // }
        let mut minutes = hours * 60 + minutes;
        let mut hours = minutes / 60;
        minutes %= 60;
        if minutes < 0 {
            hours -= 1;
            minutes += 60;
        }
        hours %= 24;
        if hours < 0 {
            hours += 24;
        }

        Self { hours, minutes }
    }

    pub fn add_minutes(&self, minutes: i32) -> Self {
        Clock::new(self.hours, self.minutes + minutes)
    }
}

impl Display for Clock {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:02}:{:02}", self.hours, self.minutes)
    }
}
