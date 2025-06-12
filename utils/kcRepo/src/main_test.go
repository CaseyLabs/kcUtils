package main

import (
    "testing"
)

// TestGreeting checks the output of the greeting function.
func TestGreeting(t *testing.T) {
    expected := "Hello, World! From Golang."
    if result := greeting(); result != expected {
        t.Errorf("greeting() = %q, want %q", result, expected)
    }
}

// TestAdd runs a series of sub-tests for the add function.
func TestAdd(t *testing.T) {
    // Test case 1: Positive numbers
    t.Run("positive numbers", func(t *testing.T) {
        result := add(10, 5)
        expected := 15
        if result != expected {
            t.Errorf("add(10, 5) = %d; want %d", result, expected)
        }
    })

    // Test case 2: Negative and positive numbers
    t.Run("negative and positive numbers", func(t *testing.T) {
        result := add(-5, 10)
        expected := 5
        if result != expected {
            t.Errorf("add(-5, 10) = %d; want %d", result, expected)
        }
    })

    // Test case 3: Zero
    t.Run("zeros", func(t *testing.T) {
        result := add(0, 0)
        expected := 0
        if result != expected {
            t.Errorf("add(0, 0) = %d; want %d", result, expected)
        }
    })
}