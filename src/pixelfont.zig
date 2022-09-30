const std = @import("std");

pub const Mask = std.meta.Int(.unsigned, WIDTH * HEIGHT);
pub const Char = packed struct { mask: Mask = 0, code: u16 };

pub const WIDTH = 5;
pub const HEIGHT = 9;
pub const CHARS = parse: {
  @setEvalBranchQuota(1_000_000);

  var chars: [0x100]Char = undefined;
  var chars_idx: usize = 0;

  var cursor: usize = 0;
  while (std.mem.indexOfScalarPos(u8, CHARMAP, cursor, 'u')) |i| : (cursor = i + 1) {
    const hex = CHARMAP[i..][1..5];
    const code = std.fmt.parseUnsigned(u16, hex, 16) catch unreachable;
    var char = Char{ .code = code };

    var y: u6 = 0;
    while (y < HEIGHT) : (y += 1) {
      var x: u6 = 0;
      while (x < WIDTH) : (x += 1) {
        if (CHARMAP[CHARMAP_WIDTH * (y + 1) + x + i] != ' ')
          char.mask |= 1 << WIDTH * y + x;
      }
    }

    chars[chars_idx] = char;
    chars_idx += 1;
  }

  break :parse chars[0..chars_idx].*;
};

const CHARMAP_WIDTH = 1 + std.mem.indexOfScalar(u8, CHARMAP, '\n').?;
const CHARMAP =
  \\| ufffd u0020 u0021 u0022 u0023 u0024 u0025 u0026 u0027 u0028 u0029 u002a |
  \\| o o o         o    o o   o o   ooo  o   o  oo     o     oo   oo     o   |
  \\|               o    o o   o o  o o o o   o o  o    o    o       o  o o o |
  \\| o   o         o         ooooo o o      o  o            o       o   ooo  |
  \\|               o          o o   ooo    o    o           o       o  o o o |
  \\| o   o         o         ooooo   o o  o    o o o        o       o    o   |
  \\|                          o o  o o o o   o o  o         o       o        |
  \\| o   o         o          o o   ooo  o   o  oo o        o       o        |
  \\|                                                        o       o        |
  \\| o o o                                                   oo   oo         |
  \\| u002b u002c u002d u002e u002f u0030 u0031 u0032 u0033 u0034 u0035 u0036 |
  \\|                            o   ooo    o    ooo   ooo     o  ooooo  ooo  |
  \\|                            o  o   o  oo   o   o o   o   oo  o     o     |
  \\|   o                        o  o  oo o o       o     o  o o  o     o     |
  \\|   o                       o   o o o   o      o    oo  o  o  oooo  oooo  |
  \\| ooooo       ooooo         o   oo  o   o     o       o ooooo     o o   o |
  \\|   o     o           o     o   o   o   o    o    o   o    o      o o   o |
  \\|   o     o           o    o     ooo  ooooo ooooo  ooo     o  oooo   ooo  |
  \\|        o                 o                                              |
  \\|                          o                                              |
  \\| u0037 u0038 u0039 u003a u003b u003c u003d u003e u003f u0040 u0041 u0042 |
  \\| ooooo  ooo   ooo                                 ooo   ooo   ooo  oooo  |
  \\|     o o   o o   o                               o   o o   o o   o o   o |
  \\|    o  o   o o   o   o     o      o         o        o o ooo o   o o   o |
  \\|   o    ooo   oooo   o     o     o   ooooo   o      o  o o o ooooo oooo  |
  \\|   o   o   o     o              o             o    o   o o o o   o o   o |
  \\|   o   o   o     o   o     o     o   ooooo   o         o o o o   o o   o |
  \\|   o    ooo   ooo    o     o      o         o      o   o ooo o   o oooo  |
  \\|                          o                            o                 |
  \\|                                                        ooo              |
  \\| u0043 u0044 u0045 u0046 u0047 u0048 u0049 u004a u004b u004c u004d u004e |
  \\|  ooo  oooo  ooooo ooooo  ooo  o   o ooooo   ooo o   o o     o   o o   o |
  \\| o   o o   o o     o     o   o o   o   o       o o   o o     oo oo oo  o |
  \\| o     o   o o     o     o     o   o   o       o o  o  o     o o o o o o |
  \\| o     o   o oooo  oooo  o  oo ooooo   o       o ooo   o     o   o o  oo |
  \\| o     o   o o     o     o   o o   o   o       o o  o  o     o   o o   o |
  \\| o   o o   o o     o     o   o o   o   o   o   o o   o o     o   o o   o |
  \\|  ooo  oooo  ooooo o      ooo  o   o ooooo  ooo  o   o ooooo o   o o   o |
  \\|                                                                         |
  \\|                                                                         |
  \\| u004f u0050 u0051 u0052 u0053 u0054 u0055 u0056 u0057 u0058 u0059 u005a |
  \\|  ooo  oooo   ooo  oooo   ooo  ooooo o   o o   o o   o o   o o   o ooooo |
  \\| o   o o   o o   o o   o o   o   o   o   o o   o o   o o   o o   o     o |
  \\| o   o o   o o   o o   o o       o   o   o o   o o   o  o o   o o     o  |
  \\| o   o oooo  o   o oooo   ooo    o   o   o o   o o   o   o     o     o   |
  \\| o   o o     o   o o   o     o   o   o   o o   o o o o  o o    o    o    |
  \\| o   o o     o  o  o   o o   o   o   o   o  o o  oo oo o   o   o   o     |
  \\|  ooo  o      oo o o   o  ooo    o    ooo    o   o   o o   o   o   ooooo |
  \\|                                                                         |
  \\|                                                                         |
  \\| u005b u005c u005d u005e u005f u0060 u0061 u0062 u0063 u0064 u0065 u0066 |
  \\|  ooo   o     ooo    o          o          o               o         ooo |
  \\|  o     o       o   o o          o         o               o        o    |
  \\|  o     o       o  o   o              ooo  oooo   oooo  oooo  ooo  oooo  |
  \\|  o      o      o                        o o   o o     o   o o   o  o    |
  \\|  o      o      o                     oooo o   o o     o   o ooooo  o    |
  \\|  o      o      o                    o   o o   o o     o   o o      o    |
  \\|  o       o     o                     oooo oooo   oooo  oooo  oooo  o    |
  \\|  o       o     o                                                        |
  \\|  ooo     o   ooo        ooooo                                           |
  \\| u0067 u0068 u0069 u006a u006b u006c u006d u006e u006f u0070 u0071 u0072 |
  \\|       o       o       o o     ooo                                       |
  \\|       o                 o       o                                       |
  \\|  oooo oooo  ooo     ooo o   o   o   oooo  oooo   ooo  oooo   oooo o oo  |
  \\| o   o o   o   o       o o   o   o   o o o o   o o   o o   o o   o oo  o |
  \\| o   o o   o   o       o oooo    o   o o o o   o o   o o   o o   o o     |
  \\| o   o o   o   o       o o   o   o   o o o o   o o   o o   o o   o o     |
  \\|  oooo o   o ooooo     o o   o ooooo o o o o   o  ooo  oooo   oooo o     |
  \\|     o             o   o                               o         o       |
  \\|  ooo               ooo                                o         o       |
  \\| u0073 u0074 u0075 u0076 u0077 u0078 u0079 u007a u007b u007c u007d u007e |
  \\|        o                                          oo    o    oo    o    |
  \\|        o                                         o      o      o  o o o |
  \\|  oooo oooo  o   o o   o o o o o   o o   o ooooo  o      o      o     o  |
  \\| o      o    o   o o   o o o o o   o o   o    o   o      o      o        |
  \\|  ooo   o    o   o o   o o o o  ooo  o   o   o   o       o       o       |
  \\|     o  o    o   o  o o  o o o o   o o   o  o     o      o      o        |
  \\| oooo    ooo  oooo   o    oooo o   o  oooo ooooo  o      o      o        |
  \\|                                         o        o      o      o        |
  \\|                                      ooo          oo    o    oo         |
  \\| u0085 u00b7 u2022                                                       |
  \\|                                                                         |
  \\|                                                                         |
  \\|                                                                         |
  \\|              ooo                                                        |
  \\|         o    ooo                                                        |
  \\| o o o        ooo                                                        |
  \\| o o o                                                                   |
  \\|                                                                         |
  \\|                                                                         |
;
