{nixtest, ...}:
nixtest.run {
  name = "smoke-test";
  tests = [
    {
      name = "true-is-true";
      expected = true;
      actual = true;
    }
  ];
}
