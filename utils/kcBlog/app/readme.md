# `kcBlog/app/main.py`    
Generates a static website from Markdown files    
- HTML template file: template.html  

- Recursively walks through the `input_dir` directory    

- Parses any Markdown files found   

- Converts the Markdown content to HTML  

- HTML files are written to `./output`    

- Downloads a CSS file from a URL defined by `kcBlogCssUrl`, and saves it to `./output/static`  

