/// Check a Luhn checksum.
pub fn is_valid(code: &str) -> bool {
    let mut sum = 0;
    let mut count = 0;
    for c in code.chars().rev() {
        if c.is_whitespace() {
            continue;
        }
        if let Some(digit) = c.to_digit(10) {
            if count % 2 == 1 {
                sum += digit * 2 - if digit > 4 { 9 } else { 0 };
            } else {
                sum += digit;
            }
            count += 1;
        } else {
            return false;
        }
    }
    count > 1 && sum % 10 == 0
}
