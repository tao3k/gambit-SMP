"""Property checks for one rest grant. Same arithmetic as rest_caller_frame_grant.

These checks do not execute a GSI and do not admit a native receipt.
"""
import random
import unittest

PAIR_WORDS = 3
VECTOR_HEADER = 1


def fast_words(pending):
    return pending * PAIR_WORDS


def retry_words(pending, params):
    return fast_words(pending) + params + VECTOR_HEADER


def fits(hp, words, end):
    return hp >= 0 and words > 0 and hp <= end and words <= end - hp


def shrink_shortfall(hp, words, end):
    """Reduce a refusing interval until one more word would admit it."""
    if fits(hp, words, end) or words <= 0 or hp < 0 or hp > end:
        return None
    while end + 1 - hp < words and end > hp:
        end -= 1
    return hp, words, end


class RestCallerFrameGrantProperties(unittest.TestCase):
    def test_selected_layout_boundaries(self):
        self.assertEqual(fast_words(4000), 12000)
        self.assertEqual(retry_words(4000, 1), 12002)
        self.assertTrue(fits(0, PAIR_WORDS, 100))
        self.assertFalse(fits(0, fast_words(4000), 11999))
        self.assertTrue(fits(0, fast_words(4000), 12000))
        self.assertFalse(fits(0, retry_words(4000, 1), 12001))
        self.assertTrue(fits(0, retry_words(4000, 1), 12002))

    def test_exact_and_one_short_for_drawn_batches(self):
        seed = 17
        drawn = random.Random(seed)
        for _ in range(200):
            pending = drawn.randint(1, 4000)
            params = drawn.randint(1, 8)
            words = retry_words(pending, params)
            hp = drawn.randint(0, 50)
            self.assertTrue(fits(hp, words, hp + words))
            self.assertFalse(fits(hp, words, hp + words - 1))
            self.assertEqual(shrink_shortfall(hp, words, hp + words - 1),
                             (hp, words, hp + words - 1))

    def test_shortfall_shrinks_to_one_word(self):
        hp, words, end = 10, retry_words(40, 2), 10
        shrunk = shrink_shortfall(hp, words, end)
        self.assertEqual(shrunk, (hp, words, hp))
        self.assertFalse(fits(*shrunk))
        self.assertTrue(fits(hp, words, hp + words))

    def test_refusal_keeps_zero_writes_and_one_entry_needs_a_grant(self):
        writes = pops = entries = 0
        granted = fits(0, retry_words(4000, 1), 12001)
        if granted:
            writes, pops, entries = fast_words(4000), 4000, 1
        self.assertFalse(granted)
        self.assertEqual((writes, pops, entries), (0, 0, 0))


if __name__ == "__main__":
    unittest.main()
