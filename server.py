import socket
import time
import socketio
import pyautogui
import eventlet

sio = socketio.Server()
last_update_time = 0
update_interval = 0.11  # Adjust the interval as needed

@sio.on('move_mouse')
def move_mouse(sid, data):
    global last_update_time

    if 'x' in data and 'y' in data:
        current_time = time.time()
        if current_time - last_update_time >= update_interval:
            # print(data.items())
            x = data['x']
            y = data['y']
            # Move the mouse pointer on the laptop using pyautogui
            # Adjust the scaling and offset values as needed
            screen_width, screen_height = pyautogui.size()
            # print(screen_height,screen_width)
            scaled_x = (x/300)*screen_width
            scaled_y = (y/700)*screen_height
            pyautogui.moveTo(scaled_x, scaled_y)
            last_update_time = current_time
        else:
            # print("'x' and 'y' keys not found in data dictionary.")
            pass

@sio.on('left')
def left(sid):
    pyautogui.click(button='left')

@sio.on('right')
def right(sid):
    pyautogui.click(button='right')

# Replace 'YOUR_SOCKET_SERVER_PORT' with the same port you specified in the Flutter app
if __name__ == '__main__':
    hostname = socket.gethostname()
    IPAddr = socket.gethostbyname(hostname)
    app = socketio.WSGIApp(sio)
    eventlet.wsgi.server(eventlet.listen((IPAddr, 12346)), app)
