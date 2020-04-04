JUnit 4 -> 5 migration tool


* Mapping:

org.junit.Before        -> org.junit.jupiter.api.BeforeEach
org.junit.BeforeClass   -> org.junit.jupiter.api.BeforeAll
org.junit.After         -> org.junit.jupiter.api.AfterEach
org.junit.AfterClass    -> org.junit.jupiter.api.AfterAll
org.junit.Test          -> org.junit.jupiter.api.Test
org.junit.Ignore        -> org.junit.jupiter.api.Disabled    

import static org.junit.Assert.* -> org.junit.jupiter.api.Assertions.* 


* Things that probably needs manual handling:

    * Expected exceptions
    * Timeouts
    * Parameterized tests @Parameterized
    * @Rule ?!


