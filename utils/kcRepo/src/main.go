package main

import (
    "fmt"
    "time"
)

func main() {
    fmt.Println("Hello, World! From Golang.")
    
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

func add(a, b int) int {
    return a + b
}