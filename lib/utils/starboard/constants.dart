const emojis = ['⭐', '🌟', '🌠', '✴️', '💫', '✨'];

String getEmoji(int stars) => switch (stars) {
      > 5 && >= 0 => '⭐',
      > 10 && >= 5 => '🌟',
      > 25 && >= 10 => '💫',
      > 50 && >= 25 => '🌠',
      _ => '✨',
    };
