// https://nullprogram.com/blog/2018/07/31/
// https://github.com/skeeto/hash-prospector

uint hp2(uint x) {
  x = (x ^ x >> 16u) * 0x7feb352du;
  x = (x ^ x >> 15u) * 0x846ca68bu;
  return x ^ x >> 16u;
}

uint hp3(uint x) {
  x = (x ^ x >> 17u) * 0xed5ad4bbu;
  x = (x ^ x >> 11u) * 0xac4c1b51u;
  x = (x ^ x >> 15u) * 0x31848babu;
  return x ^ x >> 14u;
}

// https://github.com/skeeto/hash-prospector/issues/19

uint hp2b(uint x) {
  x = (x ^ x >> 16u) * 0x21f0aaadu;
  x = (x ^ x >> 15u) * 0xd35a2d97u;
  return x ^ x >> 15u;
}
