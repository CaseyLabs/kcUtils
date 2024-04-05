import os
import markdown
import subprocess

def generate_site(input_dir, output_dir):
    for root, dirs, files in os.walk(input_dir):
        dirs[:] = [d for d in dirs if not d.startswith('_')]
        
        for name in files:
            if name.endswith('.md'):
                input_file_path = os.path.join(root, name)
                output_file_path = os.path.join(output_dir, os.path.relpath(input_file_path, input_dir))
                output_file_path = os.path.splitext(output_file_path)[0] + '.html'
                os.makedirs(os.path.dirname(output_file_path), exist_ok=True)
                
                with open(input_file_path, 'r') as f:
                    content = f.read()
                    md = markdown.Markdown(extensions=['toc'])
                    html_content = md.convert(content)
                    with open(output_file_path, 'w') as html_file:
                        html_file.write('<!DOCTYPE html>\n')
                        html_file.write('<html lang="en">\n')
                        html_file.write('<head>\n')
                        html_file.write('    <meta charset="UTF-8">\n')
                        html_file.write('    <meta name="viewport" content="width=device-width, initial-scale=1.0">\n')
                        
                        h1_tag = md.toc_tokens[0].get('name', '') if md.toc_tokens else ''
                        
                        html_file.write('    <title>' + h1_tag + '</title>\n')
                        
                        depth = input_file_path.count(os.sep) - 2
                        css_path = '../' * depth + 'static/main.css'
                        html_file.write('    <link rel="stylesheet" href="' + css_path + '">\n')
                            
                        html_file.write('</head>\n')
                        html_file.write('<body>\n')
                        
                        relative_path = os.path.relpath(root, input_dir)
                        if relative_path != '.':
                            html_file.write('<div class="breadcrumbs">\n')
                            home_path = '../' * depth + 'index.html'
                            html_file.write('<a href="' + home_path + '">Home</a>\n')
                            for i, part in enumerate(relative_path.split(os.sep)):
                                html_file.write(' / <a href="' + '../' * (len(relative_path.split(os.sep)) - i - 1) + 'index.html">' + part + '</a>')
                            html_file.write('</div>\n')
                        
                        # html_file.write('<h1>' + h1_tag + '</h1>\n')  # Commented out this line
                        html_file.write('<div class="toc">\n' + md.toc + '</div>\n')
                        html_file.write('<div class="content">\n' + html_content + '</div>\n')
                        html_file.write('</body>\n')
                        html_file.write('</html>\n')

        if dirs or root != input_dir:
            index_file_path = os.path.join(output_dir, os.path.relpath(root, input_dir), 'index.html')
            with open(index_file_path, 'a') as index_file:
                for dir in dirs:
                    index_file.write('<a href="' + dir + '/index.html">' + dir + '</a><br>\n')

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