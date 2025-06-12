package main

import (
    "fmt"
    "time"
)

// greeting returns the classic "Hello, World!" message.
func greeting() string {
    return "Hello, World! From Golang."
}

// add returns the sum of two integers.
func add(a, b int) int {
    return a + b
}

func main() {
    fmt.Println(greeting())

    // Display current time
    currentTime := time.Now()
    fmt.Printf("Current time: %s\n", currentTime.Format(time.RFC3339))

    // Simple loop example
    for i := 1; i <= 5; i++ {
        fmt.Printf("Count: %d\n", i)
    }

    // Function call example
    result := add(10, 5)
    fmt.Printf("10 + 5 = %d\n", result)
}