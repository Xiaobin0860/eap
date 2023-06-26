#[macro_export]
macro_rules! hashmap {
    () => {
        ::std::collections::HashMap::new()
    };
    ( $( $key:expr => $value:expr ),+ $(,)? ) => {
        {
            let mut map = $crate::hashmap!();
            $(
                map.insert($key, $value);
            )+
            map
        }
    };
}
