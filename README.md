dither
---

Демка реализующая дизеринг по [крутым][1] [демкам][2].

```bash
$ zig build run -- examples/gradient.ppm result/output.ppm
```

В качестве входных и выходных изображении поддержан только формат [netbpm][3] и то в минимальной реализации.

В демке используется перемещанное ядро `Kernel4x4`, но также доступны два базовых ядра для использования
```zig
const dither = @import("dither.zig");
const kernel = @import("kernel.zig");

// ...

_ = try dither.process(..., kernel.Kernel2x2, ...);
_ = try dither.process(..., kernel.Kernel4x4, ...);
```

[1]: https://visualrambling.space/dithering-part-1/
[2]: https://visualrambling.space/dithering-part-2/
[3]: https://en.wikipedia.org/wiki/Netpbm
