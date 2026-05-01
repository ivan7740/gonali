use rand::Rng;

/// Alphabet excludes confusable characters: 0/O, 1/I/L.
const ALPHABET: &[u8] = b"23456789ABCDEFGHJKMNPQRSTUVWXYZ";

/// Generate a fresh 6-character invite code.
pub fn generate() -> String {
    let mut rng = rand::thread_rng();
    (0..6)
        .map(|_| ALPHABET[rng.gen_range(0..ALPHABET.len())] as char)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn six_chars_from_safe_alphabet() {
        for _ in 0..200 {
            let code = generate();
            assert_eq!(code.len(), 6);
            for c in code.chars() {
                assert!(c.is_ascii_alphanumeric(), "non-alnum: {c}");
                assert!(!"01ILO".contains(c), "confusable: {c}");
            }
        }
    }

    #[test]
    fn variability() {
        let a = generate();
        let b = generate();
        // Vanishingly unlikely to be equal — ~1 in 31^6 ≈ 1 in 887M.
        assert_ne!(a, b);
    }
}
