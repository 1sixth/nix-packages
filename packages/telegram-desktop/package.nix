{ telegram-desktop }:

telegram-desktop.override {
  unwrapped = telegram-desktop.unwrapped.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [ ./disable-ads.patch ];
  });
}
