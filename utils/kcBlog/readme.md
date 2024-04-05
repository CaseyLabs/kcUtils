# kcBlog

A simple HTML static site generator (SSG) for markdown files, written in Python.

## Requirements

- Docker

## Usage

In Terminal, run:

```shell
cd kcBlog

# Generate a website to ./output
make run
```

## Overview

This project takes a directory of markdown files (`./input`), and generates a static website with HTML files (`./output`).

The generated website includes a table of contents for each markdown file, as well as site breadcrumb navigation.

## Config

Set your site name by modifying the `kcSiteName` variable in:

`./config/settings.env`

Default value: "kcBlog"

## Demo

![Image of kcBlog running](./demo.gif)
