from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
import os, sys
os.chdir(os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build', 'web'))
class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()
ThreadingHTTPServer(('127.0.0.1', int(sys.argv[1]) if len(sys.argv) > 1 else 8765), Handler).serve_forever()
