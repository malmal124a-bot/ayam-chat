class RocketSvgaAssets {
  // Rocket Levels (1 to 5) - Mapping to exact filenames on disk
  static String getLevelSvga(int level) {
    if (level == 5) {
      return 'rocket/rocket.svga.svga';
    }
    return 'rocket/ic_crysta_level_$level.svga';
  }

  // Broadcast Banners (1 to 5)
  static String getBroadcastSvga(int level) {
    return 'rocket/crystal_broadcast_lv$level.svga';
  }

  // Countdown & Explosion Effects (1 to 5)
  static String getExplosionSvga(int level) {
    return 'rocket/ic_crysta_countdown_explosion$level.svga';
  }
}
