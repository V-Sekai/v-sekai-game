## Unit testing starter

From Jo:

The goal is to test a single system (generally a class, struct, etc) in isolation

If that system has any dependencies, they should be mocked. mocking them just means using a fake object that you can monitor to make sure the system-under-test (SUT, or test subject) actually interacted with the dependencies in the way you expected
your unit test will follow 3 parts: setup, act, and verify

In the setup phase, you'll:

  - create mock dependencies
  - create input values
  - create your test subject

For the act phase, you'll call a method or do something with the test subject, giving it whatever inputs it needs.

During verification, you'll check:

  - test subject returned what was expected
  - if the test subject was supposed to interact with any dependencies, you'll check the mocks to make sure they were called how you expected.