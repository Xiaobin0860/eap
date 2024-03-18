use std::collections::HashMap;

pub type Value = i32;
pub type Result<T> = std::result::Result<T, Error>;
pub type ForthResult = Result<()>;

#[derive(Debug, Default)]
pub struct Forth {
    stack: Vec<Value>,
    def_words_map: HashMap<String, Vec<Vec<Word>>>,
}

#[derive(Debug, Clone)]
enum Word {
    Add,
    Sub,
    Mul,
    Div,
    Dup,
    Drop,
    Swap,
    Over,
    Num(Value),
    Call { word: String, version: usize },
}

#[derive(Debug, PartialEq, Eq)]
pub enum Error {
    DivisionByZero, //"4 0 /"
    StackUnderflow, //"1 +" "+" "dup" "drop" "1 swap"
    UnknownWord,    //"1 foo"
    InvalidWord,    //": 1 2 ;" ": foo 1"
}

impl Forth {
    pub fn new() -> Forth {
        Default::default()
    }

    pub fn stack(&self) -> &[Value] {
        &self.stack
    }

    pub fn eval(&mut self, input: &str) -> ForthResult {
        let mut iter = input.split_whitespace();
        while let Some(word) = iter.next() {
            match word {
                ":" => {
                    let name = iter
                        .next()
                        .filter(|&w| w.parse::<Value>().is_err())
                        .ok_or(Error::InvalidWord)?;
                    let mut defs = Vec::new();
                    while let Some(word) =
                        Some(iter.next().ok_or(Error::InvalidWord)?).filter(|&w| w != ";")
                    {
                        defs.push(self.parse_word(word)?);
                    }
                    self.def_words_map
                        .entry(name.to_lowercase())
                        .or_default()
                        .push(defs);
                }
                _ => {
                    let word = self.parse_word(word)?;
                    self.eval_word(&word)?;
                }
            }
        }
        Ok(())
    }

    fn parse_word(&self, word: &str) -> Result<Word> {
        let word = word.to_lowercase();
        if let Some(defs) = self.def_words_map.get(&word) {
            return Ok(Word::Call {
                word: word.clone(),
                version: defs.len() - 1,
            });
        }
        match &word[..] {
            "+" => Ok(Word::Add),
            "-" => Ok(Word::Sub),
            "*" => Ok(Word::Mul),
            "/" => Ok(Word::Div),
            "dup" => Ok(Word::Dup),
            "drop" => Ok(Word::Drop),
            "swap" => Ok(Word::Swap),
            "over" => Ok(Word::Over),
            _ => match word.parse::<Value>() {
                Ok(num) => Ok(Word::Num(num)),
                Err(_) => Err(Error::UnknownWord),
            },
        }
    }

    fn eval_word(&mut self, word: &Word) -> ForthResult {
        match word {
            Word::Add => self.math(|a, b| Ok(a + b)),
            Word::Sub => self.math(|a, b| Ok(a - b)),
            Word::Mul => self.math(|a, b| Ok(a * b)),
            Word::Div => self.math(|a, b| {
                if b == 0 {
                    Err(Error::DivisionByZero)
                } else {
                    Ok(a / b)
                }
            }),
            Word::Dup => self.dup(),
            Word::Drop => self.drop(),
            Word::Swap => self.swap(),
            Word::Over => self.over(),
            Word::Num(num) => {
                self.stack.push(*num);
                Ok(())
            }
            Word::Call { word, version } => self.call(word, *version),
        }
    }

    fn math<F>(&mut self, op: F) -> ForthResult
    where
        F: FnOnce(Value, Value) -> Result<Value>,
    {
        let rhs = self.pop()?;
        let lhs = self.pop()?;
        self.stack.push(op(lhs, rhs)?);
        Ok(())
    }

    fn pop(&mut self) -> Result<Value> {
        self.stack.pop().ok_or(Error::StackUnderflow)
    }

    fn dup(&mut self) -> ForthResult {
        let &top = self.pick()?;
        self.stack.push(top);
        Ok(())
    }

    fn drop(&mut self) -> ForthResult {
        self.pop()?;
        Ok(())
    }

    fn swap(&mut self) -> ForthResult {
        let a = self.pop()?;
        let b = self.pop()?;
        self.stack.push(a);
        self.stack.push(b);
        Ok(())
    }

    fn over(&mut self) -> ForthResult {
        let a = self.pop()?;
        let &b = self.pick()?;
        self.stack.push(a);
        self.stack.push(b);
        Ok(())
    }

    fn pick(&mut self) -> Result<&Value> {
        self.stack.last().ok_or(Error::StackUnderflow)
    }

    fn call(&mut self, word: &str, version: usize) -> ForthResult {
        let defs = self
            .def_words_map
            .get(word)
            .unwrap()
            .get(version)
            .unwrap()
            .clone();
        for word in defs {
            self.eval_word(&word)?;
        }
        Ok(())
    }
}
