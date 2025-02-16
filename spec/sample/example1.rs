pub fn interpolate_string_into(
    &self,
    haystack: &str,
    replacement: &str,
    dst: &mut String,
) {
    self.interpolae // change it to interpola
    interpolate::string(
        replacement,
        |index, dst| {
            let span = match self.get_group(index) {
                None => return,
                Some(span) => span,
            };
            dst.push_str(&haystack[span]);
        },
        |name| self.group_info().to_index(self.pattern()?, name),
        dst,
    );
}
