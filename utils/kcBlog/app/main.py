#| # `kcBlog/app/main.py`  
#| Generates a static website from Markdown files  

import os
import markdown
import subprocess
import string

def generate_site(input_dir, output_dir):
  #| - HTML template file: template.html
  with open('./app/template.html', 'r') as template_file:
    template = string.Template(template_file.read())

  # Retrieve the site name from environment variable
  site_name = os.getenv('kcSiteName', 'kcBlog')
  site_description = os.getenv('kcSiteDescription', 'A simple static site generator.')

  #| - Recursively walks through the `input_dir` directory  
  for root, dirs, files in os.walk(input_dir):
    dirs[:] = sorted([d for d in dirs if not d.startswith('_')])

    subfolders = ''
    for dir in dirs:
      subfolders += '<a href="' + dir + '/index.html">' + dir + '</a>\n'
    
    #| - Parses any Markdown files found 
    for name in files:
      if name.endswith('.md'):
        input_file_path = os.path.join(root, name)
        output_file_path = os.path.join(output_dir, os.path.relpath(input_file_path, input_dir))
        output_file_path = os.path.splitext(output_file_path)[0] + '.html'
        os.makedirs(os.path.dirname(output_file_path), exist_ok=True)
        
        #| - Converts the Markdown content to HTML
        with open(input_file_path, 'r') as f:
          content = f.read()
          md = markdown.Markdown(extensions=['toc'])
          html_content = md.convert(content)
          
          h1_tag = md.toc_tokens[0].get('name', '') if md.toc_tokens else ''
          depth = input_file_path.count(os.sep) - 2
          css_path = '../' * depth + 'static/main.css'
          home_path = '../' * depth + 'index.html'
          relative_path = os.path.relpath(root, input_dir)
          breadcrumbs = ''
          if relative_path != '.':
            breadcrumbs = '<div class="breadcrumbs">\n'
            breadcrumbs += '<a href="' + home_path + '">Home</a>\n'
            for i, part in enumerate(relative_path.split(os.sep)):
              breadcrumbs += ' / <a href="' + '../' * (len(relative_path.split(os.sep)) - i - 1) + 'index.html">' + part + '</a>'
            breadcrumbs += '</div>\n'
          
          #| - HTML files are written to `./output`  
          with open(output_file_path, 'w') as html_file:
            # Substitute placeholders in the template with actual content
            # Do not generate toc for root index.html
            toc = md.toc if not (root == input_dir and name == 'index.md') else ''
            html_file.write(template.substitute(
              title=h1_tag,
              css_path=css_path,
              breadcrumbs=breadcrumbs,
              toc=toc,
              content=html_content,
              site_name=site_name,  # Add site name to the template
              site_description=site_description,
              subfolders=subfolders  # Add subfolders to the template
            ))

  #| - Downloads a CSS file from a URL defined by `kcBlogCssUrl`, and saves it to `./output/static`
  static_dir = os.path.join(output_dir, 'static')
  os.makedirs(static_dir, exist_ok=True)

  css_url = os.getenv('kcBlogCssUrl', 'https://raw.githubusercontent.com/kevquirk/simple.css/main/simple.min.css')

  subprocess.run(['curl', '-o', os.path.join(static_dir, 'main.css'), '-L', css_url])

if __name__ == '__main__':
  input_dir = './input'
  output_dir = './output'

  if os.path.exists(output_dir):
    subprocess.run(f'rm -rf {os.path.join(output_dir, "*")}', shell=True)

  generate_site(input_dir, output_dir)