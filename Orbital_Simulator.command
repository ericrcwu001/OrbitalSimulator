#!/Users/ericwu/Desktop/Code/Orbital_Simulator/venv/bin/python

"""
Importing libraries for program functionality
Make sure to have all these libraries downloaded
"""
import random  # For generating random numbers
import math  # For mathematical functions
import asyncio  # For asynchronous programming
import pickle  # For object serialization
import os  # For interacting with the operating system

import pygame  # Main library for creating games
import pygame_widgets  # For additional widgets in Pygame
import pygame_gui  # For UI management in Pygame
from pygame_gui.elements import UIButton  # For creating buttons
from pygame_gui.windows.ui_file_dialog import UIFileDialog  # For file dialog UI
from pygame.locals import KEYDOWN, K_f, K_RETURN, Rect  # For handling events and constants

# Importing custom helper classes for organizing code
from helpers.cam_group import CamGroup  # For camera management
from helpers.planet_group import PlanetGroup  # For managing planets
from helpers.menu_group import MenuGroup  # For managing menus
from helpers.sprites import Planet, Star, Button, LogarithmicSlider, TextBox, Slider  # For game objects and UI elements
import matplotlib  # For plotting graphs
import matplotlib.pyplot as plt  # For creating plots
import matplotlib.backends.backend_agg as agg  # For rendering plots to surfaces

matplotlib.use('Agg')  # Use a backend for rendering plots that does not require a display

# PYGAME SETUP
pygame.init()  # Initialize all imported Pygame modules
# Set up the drawing window
screen = pygame.display.set_mode((0, 0))  # Create a window with default size
screen_width, screen_height = screen.get_width(), screen.get_height()  # Get screen dimensions
# Adjust for Mac Menu Bar since it's not fullscreen mode
screen = pygame.display.set_mode((screen_width, screen_height - 64))  # Resize window to account for menu bar
screen_width, screen_height = screen.get_width(), screen.get_height()  # Update dimensions
pygame.display.set_caption('Orbital Simulator')  # Set the window title
clock = pygame.time.Clock()  # Create a clock object to manage frame rate
# Define font sizes based on screen width for responsive design
FONT_1 = pygame.font.SysFont("Trebuchet MS", int(screen_width * 50 / 1920), bold=True)
FONT_2 = pygame.font.SysFont("Trebuchet MS", int(screen_width * 25 / 1920), bold=True)
FONT_3 = pygame.font.SysFont("Trebuchet MS", int(screen_width * 20 / 1920))
COLOR = "#d9d9d9"  # Define a color for text and UI elements
rand_color = lambda: random.randint(100, 255)  # Lambda function for generating random colors
manager = pygame_gui.UIManager((screen_width, screen_height))  # Create a UI manager for handling GUI elements

# Define menu size and button sizes
MENU_SIZE = (screen_width // 5, screen_height)  # Menu size based on screen width
menu_width, menu_height = MENU_SIZE  # Unpack menu size into variables
SETTINGS_BUTTON_SIZE = (menu_width // 5, menu_width // 5)  # Define size for settings buttons

# Buttons Group - creating buttons individually
buttons_group = pygame.sprite.Group()  # Create a sprite group for buttons
BUTTON_SIZING = 15  # Variable button sizing for ease of changing aesthetics

# Get the directory path of the current file
dir_path = os.path.dirname(os.path.realpath(__file__))  # Get the directory of the script

# Create buttons for play, pause, add, and settings actions with their images
play_button = Button(
    screen_width // BUTTON_SIZING // 2 + screen_height // BUTTON_SIZING // 2,
    screen_height - (screen_width // BUTTON_SIZING // 2 + screen_height // BUTTON_SIZING // 2),
    (screen_width // BUTTON_SIZING, screen_width // BUTTON_SIZING),
    dir_path + "/assets/images/play.png",  # Path to play button image
    "play",  # Name of the button
    sprite_group=buttons_group  # Add to buttons group
)

pause_button = Button(
    screen_width // BUTTON_SIZING // 2 * 3 + screen_height // BUTTON_SIZING // 2 * 2,
    screen_height - (screen_width // BUTTON_SIZING // 2 + screen_height // BUTTON_SIZING // 2),
    (screen_width // BUTTON_SIZING, screen_width // BUTTON_SIZING),
    dir_path + "/assets/images/pause.png",  # Path to pause button image
    "pause",
    sprite_group=buttons_group
)

add_button = Button(
    screen_width - (screen_width // BUTTON_SIZING // 2 + screen_height // BUTTON_SIZING // 2),
    screen_height - (screen_width // BUTTON_SIZING // 2 + screen_height // BUTTON_SIZING // 2),
    (screen_width // BUTTON_SIZING, screen_width // BUTTON_SIZING),
    dir_path + "/assets/images/add.png",  # Path to add button image
    "add",
    sprite_group=buttons_group
)

settings_button = Button(
    screen_width - (screen_width // BUTTON_SIZING // 2 + screen_height // BUTTON_SIZING // 2),
    screen_height - (screen_width // BUTTON_SIZING // 2 * 3 + screen_height // BUTTON_SIZING // 2 * 2),
    (screen_width // BUTTON_SIZING, screen_width // BUTTON_SIZING),
    dir_path + "/assets/images/settings.png",  # Path to settings button image
    "settings",
    sprite_group=buttons_group
)

# Define x position for add and settings buttons
a_s_x_pos = screen_width - (screen_width // BUTTON_SIZING // 2 + screen_height // BUTTON_SIZING // 2)

# Load and play background music
music = pygame.mixer.Sound(dir_path + "/assets/sounds/interstellar-music.mp3")  # Load music file
music.set_volume(0.3)  # Set volume for music
music.play(-1, fade_ms=2000)  # Play music in a loop with a fade-in effect

# Create UI components for adding a planet
name_text_box = TextBox(screen, -500000, -500000, menu_width - menu_width // 4, menu_height // 25,
                        fontSize=50, placeholderText="Name", textColour=COLOR, radius=5,
                        borderThickness=0, colour="#3c3c3c", font=FONT_3)  # Text box for planet name
mass_slider = LogarithmicSlider(screen, -500000, -500000, menu_width - menu_width // 4 - menu_height // 80,
                                menu_height // 40,
                                FONT_3, 5, min=1.195e24, max=2.9875e25, min_text=["1/5x", "Earth"],
                                max_text=["5x", "Earth"])  # Slider for mass
velocity_slider = LogarithmicSlider(screen, -500000, -500000, menu_width - menu_width // 4 - menu_height // 80,
                                    menu_height // 40, FONT_3, 5, min=5960, max=148924, min_text=["1/5x", "Earth"],
                                    max_text=["5x", "Earth"])  # Slider for velocity
velocity_angle_slider = Slider(screen, -500000, -500000, menu_width - menu_width // 4 - menu_height // 80,
                               menu_height // 40,
                               FONT_3, min=0, max=360, min_text=["0°"], max_text=["360°"])  # Slider for velocity angle
distance_slider = LogarithmicSlider(screen, -500000, -500000, menu_width - menu_width // 4 - menu_height // 80,
                                    menu_height // 40, FONT_3, 2, min=Planet.AU / 2, max=Planet.AU * 2,
                                    min_text=["1/2x", "AU"], max_text=["2x", "AU"])  # Slider for distance

# Create button groups for different menus
add_menu_buttons = pygame.sprite.Group()  # Group for add menu buttons
add_planet_button = Button(400, 400, (400, 400), dir_path + "/assets/images/add_planet.png", "add_planet",
                           sprite_group=add_menu_buttons)  # Button for adding a planet
add_planet_group = MenuGroup(mass_slider, name_text_box, velocity_slider, velocity_angle_slider, distance_slider,
                             add_planet_button)  # Group for the add planet menu

view_menu_buttons = pygame.sprite.Group()  # Group for view menu buttons
edit_planet_button = Button(400, 400, (400, 400), dir_path + "/assets/images/edit_planet.png", "edit_planet",
                            sprite_group=view_menu_buttons)  # Button for editing a planet
delete_planet_button = Button(400, 400, (400, 400), dir_path + "/assets/images/delete_planet.png", "delete_planet",
                              sprite_group=view_menu_buttons)  # Button for deleting a planet

view_planet_group = MenuGroup(edit_planet_button, delete_planet_button)  # Group for viewing planet options

settings_menu_buttons = pygame.sprite.Group()  # Group for settings menu buttons
force_vectors_button = Button(400, 400, (400, 400), dir_path + "/assets/images/checkbox_empty.png",
                              "force_vectors", sprite_group=settings_menu_buttons)  # Button for toggling force vectors
velocity_vectors_button = Button(400, 400, (400, 400), dir_path + "/assets/images/checkbox_empty.png",
                                 "velocity_vectors",
                                 sprite_group=settings_menu_buttons)  # Button for toggling velocity vectors
toggle_if_focused_button = Button(400, 400, (400, 400), dir_path + "/assets/images/checkbox_empty.png",
                                  "toggle_if_focused",
                                  sprite_group=settings_menu_buttons)  # Button for focused toggling
export_button = Button(400, 400, (400, 400), dir_path + "/assets/images/export.png",
                       "export", sprite_group=settings_menu_buttons)  # Button for exporting data
import_button = Button(400, 400, (400, 400), dir_path + "/assets/images/import.png",
                       "import", sprite_group=settings_menu_buttons)  # Button for importing data

settings_menu_group = MenuGroup(force_vectors_button, velocity_vectors_button, toggle_if_focused_button,
                                export_button, import_button)  # Group for settings menu

edit_done_buttons = pygame.sprite.Group()  # Group for edit done buttons
edit_done_button = Button(400, 400, (400, 400), dir_path + "/assets/images/add_planet.png", "edit_done",
                          sprite_group=edit_done_buttons)  # Button to confirm edits
edit_planet_group = MenuGroup(mass_slider, velocity_slider, velocity_angle_slider,
                              edit_done_button)  # Group for editing a planet

# Hide all menus initially
add_planet_group.hide()  # Hide add planet menu
view_planet_group.hide()  # Hide view planet menu
settings_menu_group.hide()  # Hide settings menu
edit_planet_group.hide()  # Hide edit planet menu

# Create camera group for managing camera movements
cam_group = CamGroup()  # Instantiate camera group

check_if_added = False  # Flag to check if buttons are added


# Function to reset the planet group and create a sun
def reset_planet_group():
    planet_group = PlanetGroup(screen)  # Create a new planet group
    sun = Planet(planet_group, 0, 0, 30 * Planet.SCALE * 10 ** 9, (253, 184, 19), 1.98892 * 10 ** 30,
                 (screen_width, screen_height), "Sun", screen, cam_group)  # Create a sun object
    sun.sun = True  # Mark the object as the sun
    return planet_group, sun  # Return the planet group and sun object


# Create UI buttons for import and export functionality
export_ui_button = UIButton(relative_rect=Rect(-10000, -100000, 1, 1), manager=manager, text="")
import_ui_button = UIButton(relative_rect=Rect(-10000, -100000, 1, 1), manager=manager, text="")

# Reset planet group on startup
planet_group, sun = reset_planet_group()  # Initialize planet group and sun
imported = exported = False  # Flags for import/export status


# Main function to run the simulation
def main():
    run = True  # Flag to control the main loop
    pause = False  # Flag to control pause state
    show_distance = False  # Flag to show distances
    fps = True  # Flag to show FPS
    clock = pygame.time.Clock()  # Create a clock for frame rate control
    draw_line = True  # Flag for drawing lines
    menuShown = (False, "")  # Tuple to track menu visibility and type
    ticksTime = 0  # Timer for ticks

    # Load previously saved planet data if it exists
    if os.path.isfile(dir_path + "/assets/data/planets_data.pkl"):
        with open(dir_path + "/assets/data/planets_data.pkl", "rb") as f:
            planets_data = pickle.load(f)  # Load planet data from file
            for planet_data in planets_data:
                global planet_group
                t = Planet(planet_group, 0, 0, 1, (0, 0, 0), 0,
                           (screen_width, screen_height), "",
                           screen, cam_group)  # Create a planet from data
                t.load_fields(planet_data)  # Load fields from saved data

    # Create a group for background stars
    background = pygame.sprite.Group()
    for _ in range(2000):
        Star(background)  # Add stars to the background

    # Main game loop
    while run:
        c = clock.tick(60) / 1000  # Cap the frame rate at 60 FPS
        ticksTime += clock.get_rawtime()  # Update ticks time
        screen.fill("black")  # Fill the screen with black

        background.update(cam_group)  # Update background stars
        buttons_group.draw(screen)  # Draw buttons to the screen
        planet_group.update(cam_group)  # Update planets based on camera position
        events = pygame.event.get()  # Get a list of events from the event queue
        for event in events:
            # Handle quitting the game
            if event.type == pygame.QUIT or (event.type == pygame.KEYDOWN and
                                             (event.key == pygame.K_x or event.key == pygame.K_ESCAPE)):
                run = False  # Exit the main loop
            # Toggle pause state
            elif event.type == pygame.KEYDOWN and event.key == pygame.K_SLASH:
                pause = not pause  # Toggle pause
            # Toggle distance display
            elif event.type == pygame.KEYDOWN and event.key == pygame.K_d:
                show_distance = not show_distance  # Toggle distance display
            # Toggle line drawing
            elif event.type == pygame.KEYDOWN and event.key == pygame.K_s:
                draw_line = not draw_line  # Toggle line drawing
            # Reset planet group
            elif event.type == pygame.KEYDOWN and event.key == pygame.K_MINUS:
                planet_group, sun = reset_planet_group()  # Reset the planets

            # Check button collisions
            t = False
            if not t:
                t = t or play_button.check_collision()  # Check for play button collision
                if t:
                    planet_group.set_updating(True)  # Start updating planets
            if not t:
                t = t or pause_button.check_collision()  # Check for pause button collision
                if t:
                    planet_group.set_updating(False)  # Stop updating planets
            if not t:
                t = t or add_button.check_collision()  # Check for add button collision
                if t:
                    reset_menu()  # Reset the menu
                    menuShown = (True, "add")  # Show add menu
            if not t:
                t = t or settings_button.check_collision()  # Check for settings button collision
                if t:
                    reset_menu()  # Reset the menu
                    menuShown = (True, "settings")  # Show settings menu
            if not t and menuShown[0]:
                t = t or add_planet_button.check_collision()  # Check for add planet button collision
                if t:
                    # Create a new planet based on user input
                    planet = Planet(planet_group, 0, distance_slider.getValue(),
                                    10 * Planet.SCALE * 10 ** 9,
                                    (rand_color(), rand_color(), rand_color()), mass_slider.getValue(),
                                    (screen_width, screen_height), name_text_box.getText(), screen, cam_group)
                    vel = velocity_slider.getValue()  # Get velocity from slider
                    vel_angle = velocity_angle_slider.getValue()  # Get velocity angle from slider
                    # Set planet's velocity based on input
                    planet.x_vel = vel * math.cos(vel_angle * math.pi / 180)
                    planet.y_vel = vel * math.sin(vel_angle * math.pi / 180) * -1
                    reset_menu()  # Reset the menu
                    menuShown = (False, "")  # Hide menu
            if not t and menuShown[0] and menuShown[1] == "planet":
                t = t or delete_planet_button.check_collision()  # Check for delete planet button collision
                if t:
                    menuShown[2].kill()  # Remove the focused planet from the menu
                    reset_menu()  # Reset the menu
                    menuShown = (False, "")  # Hide menu
            if not t and menuShown[0] and menuShown[1] == "planet":
                t = t or edit_planet_button.check_collision()  # Check for edit planet button collision
                if t:
                    focused_planet = None  # Variable to store the focused planet
                    for planet in planet_group.sprites():
                        if planet.focused:
                            focused_planet = planet  # Set focused planet

                    # Set sliders based on the focused planet's properties
                    mass_slider.setValue(focused_planet.mass)
                    velocity_slider.setValue(math.sqrt(focused_planet.x_vel ** 2 + focused_planet.y_vel ** 2))
                    atan = math.atan2(focused_planet.y_vel * -1, focused_planet.x_vel) * 180 / math.pi
                    if atan < 0:
                        atan += 360  # Adjust angle to be within 0-360 degrees
                    velocity_angle_slider.setValue(atan)

                    reset_menu()  # Reset the menu
                    menuShown = (True, "edit", focused_planet)  # Show edit menu for the focused planet
            if not t and menuShown[0] and menuShown[1] == "planet":
                t = t or edit_planet_button.check_collision()  # Check if the edit button is clicked
                if t:
                    focused_planet = None  # Initialize focused planet variable
                    for planet in planet_group.sprites():  # Loop through planets
                        if planet.focused:  # Check if the planet is currently focused
                            focused_planet = planet  # Set the focused planet

                    # Set sliders to the focused planet's current values
                    mass_slider.setValue(focused_planet.mass)
                    velocity_slider.setValue(math.sqrt(focused_planet.x_vel ** 2 + focused_planet.y_vel ** 2))
                    atan = math.atan2(focused_planet.y_vel * -1,
                                      focused_planet.x_vel) * 180 / math.pi  # Calculate angle
                    if atan < 0:
                        atan += 360  # Adjust angle to be within 0-360 degrees
                    velocity_angle_slider.setValue(atan)

                    reset_menu()  # Reset the menu to hide it
                    menuShown = (True, "edit", focused_planet)  # Show edit menu for the focused planet

            if not t and menuShown[0] and menuShown[1] == "edit":
                t = t or edit_done_button.check_collision()  # Check if the edit done button is clicked
                if t:
                    focused_planet = None  # Initialize focused planet variable
                    for planet in planet_group.sprites():  # Loop through planets
                        if planet.focused:  # Check if the planet is currently focused
                            focused_planet = planet  # Set the focused planet

                    # Update the focused planet's properties based on slider values
                    focused_planet.mass = mass_slider.getValue()  # Update mass
                    vel = velocity_slider.getValue()  # Get velocity
                    vel_angle = velocity_angle_slider.getValue()  # Get angle
                    # Update planet's velocity based on user input
                    focused_planet.x_vel = vel * math.cos(vel_angle * math.pi / 180)
                    focused_planet.y_vel = vel * math.sin(vel_angle * math.pi / 180) * -1

                    # Reset properties related to energy and orbit
                    focused_planet.GPE, focused_planet.KE, focused_planet.distance, focused_planet.orbit = [], [], [], []

                    reset_menu()  # Reset the menu
                    menuShown = (False, "")  # Hide the menu

            if not t and menuShown[0] and menuShown[1] == "settings":
                t = t or force_vectors_button.check_collision()  # Check for force vectors button collision
                if t:
                    # Toggle force vectors display and update button image
                    if Planet.force_vectors:
                        force_vectors_button.set_img(dir_path + "/assets/images/checkbox_empty.png",
                                                     SETTINGS_BUTTON_SIZE)
                    else:
                        force_vectors_button.set_img(dir_path + "/assets/images/checkbox_checked.png",
                                                     SETTINGS_BUTTON_SIZE)
                    Planet.force_vectors = not Planet.force_vectors  # Toggle state

            if not t and menuShown[0] and menuShown[1] == "settings":
                t = t or velocity_vectors_button.check_collision()  # Check for velocity vectors button collision
                if t:
                    # Toggle velocity vectors display and update button image
                    if Planet.velocity_vectors:
                        velocity_vectors_button.set_img(dir_path + "/assets/images/checkbox_empty.png",
                                                        SETTINGS_BUTTON_SIZE)
                    else:
                        velocity_vectors_button.set_img(dir_path + "/assets/images/checkbox_checked.png",
                                                        SETTINGS_BUTTON_SIZE)
                    Planet.velocity_vectors = not Planet.velocity_vectors  # Toggle state

            if not t and menuShown[0] and menuShown[1] == "settings":
                t = t or toggle_if_focused_button.check_collision()  # Check for focused toggle button collision
                if t:
                    # Toggle focused display state and update button image
                    if Planet.only_when_focused:
                        toggle_if_focused_button.set_img(dir_path + "/assets/images/checkbox_empty.png",
                                                         SETTINGS_BUTTON_SIZE)
                    else:
                        toggle_if_focused_button.set_img(dir_path + "/assets/images/checkbox_checked.png",
                                                         SETTINGS_BUTTON_SIZE)
                    Planet.only_when_focused = not Planet.only_when_focused  # Toggle state

            if not t and menuShown[0] and menuShown[1] == "settings":
                global imported, exported  # Declare global flags for import/export
                if event.type == pygame_gui.UI_BUTTON_PRESSED:  # Check for UI button press events
                    if event.ui_element == import_ui_button:  # Check if import button is pressed
                        file_selection = UIFileDialog(rect=Rect(0, 0, 300, 300), manager=manager,
                                                      allow_picking_directories=False)  # Open file dialog for import
                        imported = True  # Set import flag
                    elif event.ui_element == export_ui_button:  # Check if export button is pressed
                        # file_selection = UIFileDialog(rect=Rect(0, 0, 300, 300), manager=manager,
                        #                               allow_picking_directories=True)  # Open file dialog for export
                        exported = True  # Set export flag
                    elif event.ui_element == file_selection.ok_button:  # Check if OK button in file dialog is pressed
                        if imported:  # If importing
                            planet_group, sun = reset_planet_group()  # Reset planet group

                            # Load planet data from the selected file
                            with open(file_selection.current_file_path, 'rb') as f:
                                planets_data = pickle.load(f)  # Load data
                                for planet_data in planets_data:
                                    t = Planet(planet_group, 0, 0, 1, (0, 0, 0), 0, (screen_width, screen_height), "",
                                               screen, cam_group)  # Create a planet object
                                    t.load_fields(planet_data)  # Load the planet's fields
                            imported = False  # Reset import flag
                    if exported:  # If exporting
                        print("here")
                        planets_data = []  # Initialize list for planet data
                        for planet in planet_group.sprites():  # Loop through planets
                            if not planet.sun:  # Skip the sun
                                planets_data.append(planet.save_fields())  # Save planet data
                        with open("planets_data.pkl", 'wb') as f:
                            pickle.dump(planets_data, f)  # Save data to file
                        exported = False  # Reset export flag

            if not t:
                temp = planet_group.check_collision(event)  # Check for collision with planets
                t = t or temp[0]  # Set flag if collision occurs
                if t and not temp[1].name == "Sun":  # If collision with a planet that is not the sun
                    reset_menu()  # Reset the menu
                    menuShown = (True, "planet", temp[1])  # Show planet menu for the collided planet

            if not t and not menuShown[0]:  # If no menu is shown
                cam_group.check_collision(event)  # Check for camera collision with events

            if event.type == KEYDOWN and event.key == K_RETURN:  # Check for enter key press
                menuShown = (False, "")  # Hide the menu
                reset_menu()  # Reset the menu

            if event.type == KEYDOWN and event.key == K_f:  # Check for FPS toggle key
                fps = not fps  # Toggle FPS display

            manager.process_events(event)  # Process Pygame GUI events

        # Manage menu visibility and drawing
        if menuShown[0]:  # If a menu is shown
            if menuShown[1] == "planet" and ticksTime >= 500:  # If viewing a planet and enough time has passed
                bring_menu(menuShown[1], menuShown[2], True, ticksTime)  # Show the planet menu with details
            elif menuShown[1] == "planet":  # If just viewing planet
                bring_menu(menuShown[1], menuShown[2], False, ticksTime)  # Show the planet menu
            elif menuShown[1] == "edit":  # If editing a planet
                bring_menu(menuShown[1], menuShown[2])  # Show the edit menu
            else:  # For other menus
                bring_menu(menuShown[1])  # Show the general menu

        # Save planet data periodically
        if ticksTime >= 500:
            planets_data = []  # Initialize list for planet data
            for planet in planet_group.sprites():  # Loop through planets
                if not planet.sun:  # Skip the sun
                    planets_data.append(planet.save_fields())  # Save planet data
            asyncio.run(save_data(planets_data))  # Save data asynchronously

        # Display FPS if the flag is set
        if fps:
            text = FONT_1.render("FPS: " + str(round(clock.get_fps())), False, "white")  # Render FPS text
            screen.blit(text, (0, 0))  # Draw FPS text on screen

        # Update and draw UI elements
        manager.update(c)  # Update Pygame GUI manager
        manager.draw_ui(screen)  # Draw GUI elements to the screen
        pygame_widgets.update(events)  # Update Pygame widgets
        cam_group.update()  # Update camera group
        pygame.display.update()  # Update the display

    pygame.quit()  # Quit Pygame when the main loop ends


# Load and prepare a temporary/dummy image file
graph = pygame.image.load(dir_path + "/assets/images/play.png").convert_alpha()  # Load play image
graph = pygame.transform.scale(graph, (menu_width - menu_width // 4, menu_width - menu_width // 4))  # Scale image

# Initialize lists for button labels
force_labels, velocity_labels, toggle_if_labels = [], [], []


# Function to bring up the appropriate menu based on type
def bring_menu(type, *args):
    menu_img = pygame.image.load(dir_path + "/assets/images/menu.png").convert_alpha()  # Load menu background image
    menu_img = pygame.transform.scale(menu_img, MENU_SIZE)  # Scale menu image
    pygame.draw.rect(menu_img, COLOR, menu_img.get_rect(), 4)  # Draw a border around the menu
    menu = pygame.Surface(MENU_SIZE)  # Create a new surface for the menu
    menu.blit(menu_img, menu_img.get_rect())  # Blit the menu image onto the surface

    widget_x_offset = screen_width * 4 // 5 + menu_width // 8  # Calculate widget X offset

    setting_heights = []  # List to keep track of setting heights for layout

    # Menu handling for adding a planet
    if type == "add":
        new_height = int(add_menu_title("Add Planet", menu))  # Add title for adding a planet
        new_height += add_menu_subtitles("Name:", menu, new_height) + menu_height // 80  # Add subtitle for name

        # Position the name text box
        name_text_box.setX(widget_x_offset - menu_height // 80)
        name_text_box.setY(new_height)

        new_height += name_text_box.getHeight() + menu_height // 80  # Update height after text box
        new_height += add_menu_subtitles("Mass: " + f'{mass_slider.getValue():.3e}kg', menu,
                                         new_height) + menu_height // 80  # Add mass subtitle

        # Position the mass slider
        mass_slider.setX(widget_x_offset)
        mass_slider.setY(new_height)

        new_height += mass_slider.getHeight() + menu_height // 40  # Update height after mass slider
        new_height += add_menu_subtitles("Velocity: " + f'{velocity_slider.getValue():.1f}m/s', menu,
                                         new_height) + menu_height // 80  # Add velocity subtitle

        # Position the velocity slider
        velocity_slider.setX(widget_x_offset)
        velocity_slider.setY(new_height)

        new_height += velocity_slider.getHeight() + menu_height // 40  # Update height after velocity slider
        new_height += add_menu_subtitles("Velocity Angle: " + f'{velocity_angle_slider.getValue():.1f}°', menu,
                                         new_height) + menu_height // 80  # Add velocity angle subtitle

        # Position the velocity angle slider
        velocity_angle_slider.setX(widget_x_offset)
        velocity_angle_slider.setY(new_height)

        new_height += velocity_angle_slider.getHeight() + menu_height // 40  # Update height after angle slider
        new_height += add_menu_subtitles("Distance: " + f'{distance_slider.getValue():.1e}m', menu,
                                         new_height) + menu_height // 80  # Add distance subtitle

        # Position the distance slider
        distance_slider.setX(widget_x_offset)
        distance_slider.setY(new_height)

        # Set size and position for the add planet button
        add_planet_button.set_size((menu_width - menu_width // 8, menu_height // 16))
        add_planet_button.set_pos(menu_width // 2 + screen_width * 4 // 5, menu_height - menu_height // 16)

        add_planet_group.show()  # Show the add planet group

    elif type == "settings":  # Menu handling for settings
        new_height = add_menu_title("Settings", menu) - menu_height // 40  # Add title for settings

        # Position the force vectors button
        force_vectors_button.set_size(SETTINGS_BUTTON_SIZE)
        force_vectors_button.set_pos(SETTINGS_BUTTON_SIZE[0] + screen_width * 4 // 5,
                                     new_height + SETTINGS_BUTTON_SIZE[0])

        # Create labels for force vectors setting
        force_label_1 = FONT_2.render("Toggle Force", False, COLOR)
        force_label_2 = FONT_2.render("Vectors", False, COLOR)
        global force_labels
        force_labels = [force_label_1, force_label_2]  # Store labels in the list
        setting_heights.append(new_height)  # Add height to settings heights
        new_height += SETTINGS_BUTTON_SIZE[0] + menu_height // 40  # Update height after button

        # Position the velocity vectors button
        velocity_vectors_button.set_size(SETTINGS_BUTTON_SIZE)
        velocity_vectors_button.set_pos(SETTINGS_BUTTON_SIZE[0] + screen_width * 4 // 5,
                                        new_height + SETTINGS_BUTTON_SIZE[0])

        # Create labels for velocity vectors setting
        velocity_label_1 = FONT_2.render("Toggle Velocity", False, COLOR)
        velocity_label_2 = FONT_2.render("Vectors", False, COLOR)
        global velocity_labels
        velocity_labels = [velocity_label_1, velocity_label_2]  # Store labels in the list
        setting_heights.append(new_height)  # Add height to settings heights
        new_height += SETTINGS_BUTTON_SIZE[0] + menu_height // 40  # Update height after button

        # Position the toggle if focused button
        toggle_if_focused_button.set_size(SETTINGS_BUTTON_SIZE)
        toggle_if_focused_button.set_pos(SETTINGS_BUTTON_SIZE[0] + screen_width * 4 // 5,
                                         new_height + SETTINGS_BUTTON_SIZE[0])

        # Create labels for toggle if focused setting
        toggle_if_label_1 = FONT_2.render("Toggle Vectors Only", False, COLOR)
        toggle_if_label_2 = FONT_2.render("When Focused Onto", False, COLOR)
        toggle_if_label_3 = FONT_2.render("Labels", False, COLOR)
        global toggle_if_labels
        toggle_if_labels = [toggle_if_label_1, toggle_if_label_2, toggle_if_label_3]  # Store labels in the list
        setting_heights.append(new_height)  # Add height to settings heights
        new_height += SETTINGS_BUTTON_SIZE[0] + menu_height // 40  # Update height after button

        pygame.draw.line(menu, COLOR, (0, new_height + menu_height // 20),
                         (menu_width, new_height + menu_height // 20), 4)  # Draw a separator line
        new_height += menu_height // 20 + menu_height // 40  # Update height

        temp_calc = (menu_width - (3 * SETTINGS_BUTTON_SIZE[0] / 2)) / 2  # Calculate button size
        im_ex_button_size = (temp_calc, temp_calc)  # Set button size

        global check_if_added
        if not check_if_added:  # If buttons haven't been added yet
            global import_ui_button  # Declare import button as global
            import_ui_button = UIButton(relative_rect=Rect(screen_width * 4 // 5 + SETTINGS_BUTTON_SIZE[0] / 2,
                                                           new_height, im_ex_button_size[0],
                                                           im_ex_button_size[1]),
                                        manager=manager, text='Import Scenario')  # Create import button

            global export_ui_button  # Declare export button as global
            export_ui_button = UIButton(
                relative_rect=Rect(screen_width * 4 // 5 + SETTINGS_BUTTON_SIZE[0] + temp_calc,
                                   new_height, im_ex_button_size[0], im_ex_button_size[1]),
                manager=manager, text='Export Scenario')  # Create export button

            settings_menu_group.sliders.append(import_ui_button)  # Add import button to settings group
            settings_menu_group.sliders.append(export_ui_button)  # Add export button to settings group
            check_if_added = True  # Set flag indicating buttons have been added

        # Set size and position for the import and export buttons
        import_button.set_size(im_ex_button_size)
        export_button.set_size(im_ex_button_size)

        import_button.set_pos(screen_width * 4 // 5 + SETTINGS_BUTTON_SIZE[0] / 2 + temp_calc / 2,
                              new_height + temp_calc / 2)  # Position import button
        export_button.set_pos(screen_width * 4 // 5 + SETTINGS_BUTTON_SIZE[0] + temp_calc * 3 / 2,
                              new_height + temp_calc / 2)  # Position export button

        settings_menu_group.show()  # Show the settings menu group

    elif type == "planet":  # If the menu type is for viewing a planet
        planet = args[0]  # Get the planet object from arguments
        planet.focused = True  # Mark this planet as focused

        # Set sliders to the planet's properties
        mass_slider.setValue(planet.mass)  # Set mass slider to the planet's mass
        velocity_slider.setValue(math.sqrt(planet.x_vel ** 2 + planet.y_vel ** 2))  # Set velocity slider
        atan = math.atan2(planet.y_vel * -1, planet.x_vel) * 180 / math.pi  # Calculate the angle of velocity
        if atan < 0:
            atan += 360  # Adjust angle to be within 0-360 degrees
        velocity_angle_slider.setValue(atan)  # Set angle slider

        # Create the menu title and subtitles for planet properties
        new_height = int(add_menu_title(planet.name, menu))  # Add the planet name as the title
        new_height += add_menu_subtitles("Mass: " + f'{mass_slider.getValue():.3e}kg', menu,
                                         new_height) + menu_height // 80  # Add mass subtitle
        new_height += add_menu_subtitles("Velocity: " + f'{velocity_slider.getValue():.1f}m/s', menu,
                                         new_height) + menu_height // 80  # Add velocity subtitle
        new_height += add_menu_subtitles("Velocity Angle: " + f'{velocity_angle_slider.getValue():.1f}°', menu,
                                         new_height) + menu_height // 80  # Add velocity angle subtitle

        # If conditions are met, run the graph update for the planet
        if args[1] and args[2] >= 500:  # If half a second has passed
            asyncio.run(change_graph(planet))  # Update the graph asynchronously

        # Get the dimensions of the surface for the graph
        graph_width, graph_height = graph.get_size()
        menu.blit(graph, ((menu_width - graph_width) / 2, new_height))  # Draw the graph on the menu

        # Set size and position for the edit button
        edit_planet_button.set_size((menu_width - menu_width // 8, menu_height // 16))
        edit_planet_button.set_pos(menu_width // 2 + screen_width * 4 // 5,
                                   menu_height - menu_height // 8 - menu_height // 64)

        # Set size and position for the delete button
        delete_planet_button.set_size((menu_width - menu_width // 8, menu_height // 16))
        delete_planet_button.set_pos(menu_width // 2 + screen_width * 4 // 5,
                                     menu_height - menu_height // 16)

        view_planet_group.show()  # Show the group of buttons for viewing planet options

    elif type == "edit":  # If the menu type is for editing a planet
        planet = args[0]  # Get the planet object from arguments
        planet.focused = True  # Mark this planet as focused

        # Create the menu title for editing the planet
        new_height = int(add_menu_title("Edit " + planet.name, menu))  # Add edit title
        new_height += add_menu_subtitles("Mass: " + f'{mass_slider.getValue():.3e}kg', menu,
                                         new_height) + menu_height // 80  # Add mass subtitle

        # Position the mass slider
        mass_slider.setX(widget_x_offset)
        mass_slider.setY(new_height)

        new_height += mass_slider.getHeight() + menu_height // 40  # Update height after mass slider
        new_height += add_menu_subtitles("Velocity: " + f'{velocity_slider.getValue():.1f}m/s', menu,
                                         new_height) + menu_height // 80  # Add velocity subtitle

        # Position the velocity slider
        velocity_slider.setX(widget_x_offset)
        velocity_slider.setY(new_height)

        new_height += velocity_slider.getHeight() + menu_height // 40  # Update height after velocity slider
        new_height += add_menu_subtitles("Velocity Angle: " + f'{velocity_angle_slider.getValue():.1f}°', menu,
                                         new_height) + menu_height // 80  # Add velocity angle subtitle

        # Position the velocity angle slider
        velocity_angle_slider.setX(widget_x_offset)
        velocity_angle_slider.setY(new_height)

        new_height += velocity_angle_slider.getHeight() + menu_height // 40  # Update height after angle slider
        new_height += add_menu_subtitles("Distance: " + f'{distance_slider.getValue():.1e}m', menu,
                                         new_height) + menu_height // 80  # Add distance subtitle

        # Set size and position for the edit done button
        edit_done_button.set_size((menu_width - menu_width // 8, menu_height // 16))
        edit_done_button.set_pos(menu_width // 2 + screen_width * 4 // 5, menu_height - menu_height // 16)

        edit_planet_group.show()  # Show the editing options group

    screen.blit(menu, (screen_width * 4 // 5, 0))  # Draw the menu on the screen

    if type == "add":  # If the menu type is for adding a planet
        add_menu_buttons.draw(screen)  # Draw buttons for adding a planet
        edit_button_label = FONT_2.render("Add Planet", False, COLOR)  # Create label for adding a planet
        add_button_label_size = edit_button_label.get_rect().size  # Get label size
        screen.blit(edit_button_label, (menu_width // 2 - add_button_label_size[0] // 2 + + screen_width * 4 // 5,
                                        menu_height - menu_height // 16 - add_button_label_size[1] // 2))  # Draw label

    elif type == "settings":  # If the menu type is for settings
        settings_menu_buttons.draw(screen)  # Draw buttons for settings
        button_size = (menu_width // 5, menu_width // 5)  # Define button size

        # Draw centered labels for settings options
        draw_button_labels_centered(force_labels, button_size[0] * 1.75 + screen_width * 4 // 5,
                                    setting_heights[0] + button_size[0])
        draw_button_labels_centered(velocity_labels, button_size[0] * 1.75 + screen_width * 4 // 5,
                                    setting_heights[1] + button_size[0])
        draw_button_labels_centered(toggle_if_labels, button_size[0] * 1.75 + screen_width * 4 // 5,
                                    setting_heights[2] + button_size[0])

    elif type == "planet":  # If the menu type is for a planet
        view_menu_buttons.draw(screen)  # Draw the buttons for viewing planets
        edit_button_label = FONT_2.render("Edit Planet", False, COLOR)  # Create label for editing a planet
        add_button_label_size = edit_button_label.get_rect().size  # Get size of the edit button label
        screen.blit(edit_button_label, (menu_width // 2 - add_button_label_size[0] // 2 + + screen_width * 4 // 5,
                                        menu_height - menu_height // 8 - add_button_label_size[
                                            1]))  # Draw the edit button label

        edit_button_label = FONT_2.render("Delete Planet", False, COLOR)  # Create label for deleting a planet
        add_button_label_size = edit_button_label.get_rect().size  # Get size of the delete button label
        screen.blit(edit_button_label, (menu_width // 2 - add_button_label_size[0] // 2 + + screen_width * 4 // 5,
                                        menu_height - menu_height // 16 - add_button_label_size[
                                            1] // 2))  # Draw the delete button label

    elif type == "edit":  # If the menu type is for editing a planet
        edit_done_buttons.draw(screen)  # Draw the buttons for confirming edits
        edit_button_label = FONT_2.render("Edit Done", False, COLOR)  # Create label for confirming edits
        add_button_label_size = edit_button_label.get_rect().size  # Get size of the confirm button label
        screen.blit(edit_button_label, (menu_width // 2 - add_button_label_size[0] // 2 + + screen_width * 4 // 5,
                                        menu_height - menu_height // 16 - add_button_label_size[
                                            1] // 2))  # Draw the confirm button label

    # Adjust positions of add and settings buttons
    add_button.change_x(a_s_x_pos - (screen_width // 5))  # Move add button to the side
    settings_button.change_x(a_s_x_pos - (screen_width // 5))  # Move settings button to the side

    return menu  # Return the constructed menu


# Function to draw button labels centered at specified position
def draw_button_labels_centered(label_list, x_pos, y_pos):
    total_height = 0  # Initialize total height for centering
    for label in label_list:  # Loop through each label
        total_height += label.get_height()  # Accumulate height of each label

    y = y_pos - total_height / 2  # Calculate starting y position for centering
    for label in label_list:  # Loop through each label again
        screen.blit(label, (x_pos, y))  # Draw each label at the specified position
        y += label.get_height()  # Increment y position for the next label


# Asynchronously save planet data to a file
async def save_data(planets_data):
    with open(dir_path + "/assets/data/planets_data.pkl", 'wb') as f:  # Open file for writing
        pickle.dump(planets_data, f)  # Serialize and save the planet data


# Asynchronously change the graph based on the planet's data
async def change_graph(planet):
    plt.close()  # Close any existing plots
    fig = plt.figure(figsize=(3, 5), dpi=100)  # Create a new figure for the graph
    ax = fig.gca()  # Get the current axes

    # Extract static data for plotting
    distance, KE, GPE = planet.distance, planet.KE, planet.GPE

    ax.plot(distance, KE, label="KE")  # Plot Kinetic Energy vs Distance
    ax.plot(distance, GPE, label="GPE")  # Plot Gravitational Potential Energy vs Distance
    ax.set_xlabel('Distance / m')  # Set x-axis label
    ax.set_ylabel('KE/GPE / J')  # Set y-axis label
    ax.legend()  # Add legend to the plot
    ax.grid()  # Enable grid on the plot
    ax.ticklabel_format(useOffset=False)  # Disable scientific notation for axes
    ax.axhline(color="black")  # Draw a horizontal line at y=0 for reference
    fig.tight_layout()  # Adjust layout to fit elements
    canvas = agg.FigureCanvasAgg(fig)  # Create a canvas for rendering the figure
    canvas.draw()  # Draw the canvas
    renderer = canvas.get_renderer()  # Get the renderer
    raw_data = renderer.tostring_rgb()  # Get raw RGB data from the canvas
    size = canvas.get_width_height()  # Get size of the canvas
    global graph  # Declare graph as global for access in other functions
    graph = pygame.image.fromstring(raw_data, size, 'RGB')  # Convert raw data to a Pygame surface


# Function to add a title to the menu
def add_menu_title(title_string, menu):
    title = FONT_1.render(title_string, True, COLOR)  # Render the title string
    menu.blit(title, ((menu_width - title.get_width()) // 2, menu_height // 40))  # Draw the title on the menu
    pygame.draw.line(menu, COLOR, (0, title.get_height() + menu_height // 20),
                     (menu_width, title.get_height() + menu_height // 20), 4)  # Draw a line under the title

    return title.get_height() + menu_height // 20 + menu_height // 40  # Return the height for layout


# Function to add subtitles to the menu
def add_menu_subtitles(subtitle_string, menu, y):
    subtitle = FONT_2.render(subtitle_string, True, COLOR)  # Render the subtitle string
    menu.blit(subtitle, (menu_width // 8 - menu_height // 80, y))  # Draw the subtitle on the menu
    return subtitle.get_height()  # Return the height of the subtitle


# Function to reset the menu state
def reset_menu():
    add_button.change_x(a_s_x_pos)  # Reset add button position
    settings_button.change_x(a_s_x_pos)  # Reset settings button position
    add_planet_group.hide()  # Hide the add planet menu
    view_planet_group.hide()  # Hide the view planet menu
    edit_planet_group.hide()  # Hide the edit planet menu
    settings_menu_group.hide()  # Hide the settings menu
    planet_group.unfocus()  # Unfocus all planets


# Entry point of the program
if __name__ == '__main__':
    main()  # Call the main function to start the simulation
