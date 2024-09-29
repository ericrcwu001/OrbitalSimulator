import os
import random  # Import random for generating random values

import pygame  # Import Pygame for game development
from pygame import gfxdraw  # Import gfxdraw for advanced drawing functions
import math  # Import math for mathematical functions

import pygame_widgets.slider  # Import slider widget for Pygame
import pygame_widgets.textbox  # Import textbox widget for Pygame
from pygame_widgets import Mouse  # Import Mouse from Pygame Widgets
from pygame_widgets.mouse import MouseState  # Import MouseState for mouse events


class Star(pygame.sprite.Sprite):  # Class to control random stars in the background
    def __init__(self, sprite_group):
        super().__init__(sprite_group)  # Initialize the parent class with the sprite group
        star_colors = [
            "lightblue",
            "white",
            "lightyellow",
            "lightgray",
            "gray",
            "darkgray",
        ]  # List of possible star colors

        self.color = random.choice(star_colors)  # Randomly select a star color
        self.surface = pygame.display.get_surface()  # Get the current display surface
        x, y = pygame.display.get_surface().get_size()  # Get the size of the display
        self.x = round(random.uniform(-600, x + 600))  # Random x position
        self.y = round(random.uniform(-600, y + 600))  # Random y position
        self.size = random.uniform(1, 1.5)  # Random size for the star

    def update(self, cam_group):  # Update method for the star
        self.draw(cam_group)  # Draw the star

    def draw(self, cam_group):  # Method to draw the star
        pos = (
            self.x + cam_group.offset.x * 0.1 * self.size,  # Adjust position based on camera offset
            self.y + cam_group.offset.y * 0.1 * self.size,
        )
        pygame.draw.circle(self.surface, self.color, pos, self.size)  # Draw the star as a circle


class PlanetaryObject(pygame.sprite.Sprite):  # Class to represent a planet
    AU = 149.6e9  # Astronomical unit in meters
    G = 6.67428e-11  # Gravitational constant
    TIMESTEP = 60 * 60 * 12  # Seconds in half a day
    SCALE = 200 / AU  # Scaling factor for rendering
    max_orbit_points = 200  # Maximum number of points in the orbit
    force_vectors = False  # Flag to show force vectors
    velocity_vectors = False  # Flag to show velocity vectors
    only_when_focused = False  # Flag for focus-based visibility

    def __init__(self, sprite_group, x, y, radius, color, mass, screen_size, name, screen, cam_group):
        super().__init__(sprite_group)  # Initialize the parent class
        self.screen = screen  # Store the screen reference
        self.name = name  # Store the name of the planet
        self.x = x  # Set the initial x position
        self.y = y  # Set the initial y position
        self.radius = radius  # Set the planet's radius
        self.color = color  # Set the planet's color
        self.mass = mass  # Set the planet's mass
        self.WIDTH = screen_size[0]  # Get screen width
        self.HEIGHT = screen_size[1]  # Get screen height
        self.orbit = []  # List to store orbit points
        self.sun = False  # Flag to indicate if this planet is the sun
        self.distance_to_sun = 0  # Distance to the sun
        self.x_vel = self.y_vel = 0  # Initialize velocity
        self.total_fx = self.total_fy = 0  # Initialize total force
        self.velocity = 0  # Initialize velocity magnitude
        self.GPE = []  # List to store gravitational potential energy
        self.KE = []  # List to store kinetic energy
        self.distance = []  # List to store distances
        self.last_pos = pygame.math.Vector2()  # Store the last position for dragging
        self.dragging = False  # Flag for dragging state
        self.focused = False  # Flag for focus state
        self.planet = pygame.draw.circle(screen, self.color, (x + cam_group.offset.x, y + cam_group.offset.y),
                                         self.radius)  # Draw the planet initially

    def draw(self, window, show, draw_line, cam_group):  # Method to draw the planet
        x = self.x * self.SCALE + (self.WIDTH / 2)  # Calculate scaled x position
        y = self.y * self.SCALE + (self.HEIGHT / 2)  # Calculate scaled y position

        if self.focused:
            pygame.draw.circle(window, "white", (x + cam_group.offset.x, y + cam_group.offset.y),
                               self.radius + 2 * PlanetaryObject.SCALE * 10 ** 9)

        # Draw the planet
        self.planet = pygame.draw.circle(window, self.color, (x + cam_group.offset.x, y + cam_group.offset.y),
                                         self.radius)

        if self.sun:
            pygame.draw.line(window, "gray", (x + cam_group.offset.x, y + cam_group.offset.y),
                             (x + cam_group.offset.x, y + cam_group.offset.y + self.SCALE * self.AU), 2)
            label = pygame.font.SysFont("Trebuchet MS", int(self.WIDTH * 25 / 1920), bold=True).render("1 AU",
                                                                                                       True,
                                                                                                       "gray")
            window.blit(label, (x + cam_group.offset.x - label.get_width(),
                                y + cam_group.offset.y - label.get_height() / 2 + 100))

        # Draw the orbit line if there are enough points
        if len(self.orbit) > 10:
            updated_points = []  # List for updated orbit points
            for point in self.orbit:  # Loop through orbit points
                x, y = point
                x = x * self.SCALE + self.WIDTH / 2  # Scale and adjust x position
                y = y * self.SCALE + self.HEIGHT / 2  # Scale and adjust y position
                updated_points.append((x + cam_group.offset.x, y + cam_group.offset.y))  # Store updated point

                # Limit the number of orbit points
                if len(updated_points) > self.max_orbit_points:
                    updated_points = updated_points[-self.max_orbit_points:]
                    self.orbit = self.orbit[-self.max_orbit_points:]

            if draw_line:  # Draw the orbit line
                pygame.draw.lines(window, self.color, False, updated_points, 1)

        # Draw force vectors if enabled
        if self.force_vectors and not self.sun and (
                self.focused == self.only_when_focused or (self.focused and not self.only_when_focused)):
            force_scale = 800 / 1e24  # Scale for force arrows
            force = math.sqrt(self.total_fx ** 2 + self.total_fy ** 2) * force_scale  # Calculate force magnitude
            theta = math.atan2(self.total_fy, self.total_fx)  # Calculate angle of the force
            force_x = math.cos(theta) * force  # Calculate x component
            force_y = math.sin(theta) * force  # Calculate y component
            self.arrow((255, 255, 255), (255, 255, 255),
                       (x + cam_group.offset.x, y + cam_group.offset.y),
                       (x + force_x + cam_group.offset.x, y + force_y + cam_group.offset.y), 4)  # Draw force arrow

        # Draw velocity vectors if enabled
        if self.velocity_vectors and not self.sun and (
                self.focused == self.only_when_focused or (self.focused and not self.only_when_focused)):
            velocity_scale = 50 / 29785  # Scale for velocity arrows
            self.arrow((153, 255, 153), (153, 255, 153),
                       (x + cam_group.offset.x, y + cam_group.offset.y),
                       (x + self.x_vel * velocity_scale + cam_group.offset.x,
                        y + self.y_vel * velocity_scale + cam_group.offset.y), 4)  # Draw velocity arrow

    def attraction(self, other):  # Method to calculate gravitational attraction to another body
        other_x, other_y = other.x, other.y  # Get other body's position
        distance_x = other_x - self.x  # Calculate distance in x
        distance_y = other_y - self.y  # Calculate distance in y
        distance = math.sqrt(distance_x ** 2 + distance_y ** 2)  # Calculate distance between bodies
        if other.sun:  # If the other body is the sun
            self.distance_to_sun = distance  # Update distance to sun
        force = self.G * self.mass * other.mass / distance ** 2  # Calculate gravitational force
        theta = math.atan2(distance_y, distance_x)  # Calculate angle of attraction
        force_x = math.cos(theta) * force  # Calculate x component of force
        force_y = math.sin(theta) * force  # Calculate y component of force
        if not other.sun:  # If the other body is not the sun
            return [force_x, force_y]  # Return force components
        if other.sun:  # If the other body is the sun
            return [force_x, force_y, force * distance * -1, distance]  # Return additional values

    def update_position(self, planet_group):  # Update the position of the planet
        self.total_fx = self.total_fy = 0  # Reset total forces
        for planet in planet_group.sprites():  # Loop through other planets
            if self == planet:  # Skip itself
                continue
            temp = self.attraction(planet)  # Calculate attraction to other planet
            self.total_fx += temp[0]  # Accumulate x force
            self.total_fy += temp[1]  # Accumulate y force
            if len(temp) == 4:  # If the other body is the sun
                self.GPE.append(temp[2])  # Append gravitational potential energy
                self.distance.append(temp[3])  # Append distance to sun

        # Update velocities based on forces
        self.x_vel += (self.total_fx / self.mass * self.TIMESTEP)  # Update x velocity
        self.y_vel += (self.total_fy / self.mass * self.TIMESTEP)  # Update y velocity
        self.velocity = math.sqrt(self.x_vel ** 2 + self.y_vel ** 2)  # Calculate velocity magnitude
        self.KE.append(0.5 * self.mass * (self.velocity ** 2))  # Append kinetic energy
        self.x += (self.x_vel * self.TIMESTEP)  # Update position based on velocity
        self.y += (self.y_vel * self.TIMESTEP)
        self.orbit.append((self.x, self.y))  # Add current position to orbit

        max_data = 5000  # Maximum data points to keep

        # Limit the length of energy and distance data
        if len(self.KE) > max_data:
            self.KE = self.KE[-max_data:]
        if len(self.GPE) > max_data:
            self.GPE = self.GPE[-max_data:]
        if len(self.distance) > max_data:
            self.distance = self.distance[-max_data:]

    def drag_planet(self, event):  # Handle dragging of the planet
        mouse_x, mouse_y = pygame.mouse.get_pos()  # Get mouse position
        # If left mouse button was pressed and mouse is over the planet
        if self.planet.collidepoint(
                pygame.mouse.get_pos()) and event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            self.dragging = True  # Start dragging
            self.last_pos.x = mouse_x  # Store current mouse position
            self.last_pos.y = mouse_y
            return True  # Indicate dragging started

        # Turn off dragging if left mouse button was released
        elif event.type == pygame.MOUSEBUTTONUP and event.button == 1:
            self.dragging = False  # Stop dragging

        # If mouse moved while dragging
        if self.dragging and event.type == pygame.MOUSEMOTION:
            # Update position based on mouse movement
            self.x += (mouse_x - self.last_pos.x) / self.SCALE  # Update x position
            self.y += (mouse_y - self.last_pos.y) / self.SCALE  # Update y position
            self.orbit.append((self.x, self.y))  # Add new position to orbit
            self.last_pos.x = mouse_x  # Update last mouse position
            self.last_pos.y = mouse_y
            self.KE = list()  # Reset kinetic energy data
            self.GPE = list()  # Reset potential energy data
            self.distance = list()  # Reset distance data
            self.orbit = list()  # Reset orbit data
            return True  # Indicate dragging is ongoing

        return False  # Indicate no dragging occurred

    # CITED FROM: https://stackoverflow.com/questions/56295712/how-to-draw-a-dynamic-arrow-in-pygame
    def arrow(self, line_color, tricolor, start, end, thickness=4, triangle_radius=3):  # Draw an arrow
        rad = math.pi / 180  # Convert degrees to radians
        pygame.draw.line(self.screen, line_color, start, end, thickness)  # Draw the main line of the arrow
        rotation = (math.atan2(start[1] - end[1], end[0] - start[0])) + (math.pi / 2)  # Calculate rotation angle
        # Draw the triangle at the end of the arrow
        pygame.draw.polygon(self.screen, tricolor, ((end[0] + triangle_radius * math.sin(rotation),
                                                     end[1] + triangle_radius * math.cos(rotation)),
                                                    (end[0] + triangle_radius * math.sin(rotation - 120 * rad),
                                                     end[1] + triangle_radius * math.cos(rotation - 120 * rad)),
                                                    (end[0] + triangle_radius * math.sin(rotation + 120 * rad),
                                                     end[1] + triangle_radius * math.cos(rotation + 120 * rad))))

    def save_fields(self):  # Save planet attributes for serialization
        fields = {"name": self.name, "x": self.x, "y": self.y, "radius": self.radius, "color": self.color,
                  "mass": self.mass, "WIDTH": self.WIDTH, "HEIGHT": self.HEIGHT, "orbit": self.orbit, "sun": self.sun,
                  "distance_to_sun": self.distance_to_sun, "x_vel": self.x_vel, "y_vel": self.y_vel,
                  "total_fx": self.total_fx, "total_fy": self.total_fy, "velocity": self.velocity, "KE": self.KE,
                  "GPE": self.GPE, "distance": self.distance}  # Create a dictionary of fields
        return fields  # Return the dictionary

    def load_fields(self, fields):  # Load planet attributes from a dictionary
        self.name = fields["name"]  # Set name
        self.x = fields["x"]  # Set x position
        self.y = fields["y"]  # Set y position
        self.radius = fields["radius"]  # Set radius
        self.color = fields["color"]  # Set color
        self.mass = fields["mass"]  # Set mass
        self.WIDTH = fields["WIDTH"]  # Set screen width
        self.HEIGHT = fields["HEIGHT"]  # Set screen height
        self.orbit = fields["orbit"]  # Load orbit data
        self.sun = fields["sun"]  # Set sun status
        self.distance_to_sun = fields["distance_to_sun"]  # Load distance to sun
        self.x_vel = fields["x_vel"]  # Load x velocity
        self.y_vel = fields["y_vel"]  # Load y velocity
        self.total_fx = fields["total_fx"]  # Load total x force
        self.total_fy = fields["total_fy"]  # Load total y force
        self.velocity = fields["velocity"]  # Load velocity
        self.KE = fields["KE"]  # Load kinetic energy data
        self.GPE = fields["GPE"]  # Load gravitational potential energy data
        self.distance = fields["distance"]  # Load distance data


class Button(pygame.sprite.Sprite):  # Class to create button objects
    def __init__(self, x, y, size, filename, name, **kwargs):
        group = kwargs.get('sprite_group')  # Get the sprite group from kwargs
        if group is None:
            super().__init__()  # Initialize without a group
        else:
            super().__init__(group)  # Initialize with the provided group
        self.name = name  # Store the button's name
        self.filename = filename  # Store the filename for the button image
        self.img = pygame.transform.scale(pygame.image.load(self.filename).convert_alpha(),
                                          size)  # Load and scale the image
        self.image = pygame.Surface(size)  # Create a surface for the button
        self.image.blit(self.img, self.img.get_rect())  # Blit the image onto the surface
        self.rect = self.image.get_rect(center=(x, y))  # Get the rectangle for the button
        self.pos = (x, y)  # Store the button's position
        self.hover = False  # Initialize hover state

    def check_collision(self):  # Check if the button is clicked
        if self.rect.collidepoint(pygame.mouse.get_pos()) and pygame.mouse.get_pressed()[0]:
            return True  # Return True if clicked
        return False  # Return False otherwise

    def change_x(self, x):  # Change the x position of the button
        self.rect = self.image.get_rect(center=(x, self.pos[1]))  # Update rectangle position

    def set_pos(self, x, y):  # Set the position of the button
        self.pos = (x, y)  # Update position
        self.rect = self.image.get_rect(center=self.pos)  # Update rectangle position

    def set_size(self, size):  # Set the size of the button
        self.img = pygame.transform.scale(pygame.image.load(self.filename).convert_alpha(), size)  # Resize image
        self.image = pygame.Surface(size)  # Create a new surface
        self.image.blit(self.img, self.img.get_rect())  # Blit the new image
        self.rect = self.image.get_rect(center=self.pos)  # Update rectangle position

    def set_img(self, filename, size):  # Set a new image for the button
        self.filename = filename  # Update filename
        self.img = pygame.transform.scale(pygame.image.load(self.filename).convert_alpha(),
                                          size)  # Load and scale new image
        self.image = pygame.Surface(size)  # Create a new surface
        self.image.blit(self.img, self.img.get_rect())  # Blit the new image
        self.rect = self.image.get_rect(center=self.pos)  # Update rectangle position

    def hide(self):  # Hide the button by moving it off-screen
        self.rect = self.image.get_rect(center=(50000, 50000))  # Move to a distant position

    def show(self):  # Show the button by resetting its position
        self.rect = self.image.get_rect(center=self.pos)  # Reset rectangle position


class Slider(pygame_widgets.slider.Slider):  # Class to create slider objects
    COLOR = "#d9d9d9"  # Color constant for the slider

    def __init__(self, win, x, y, width, height, font, **kwargs):
        super().__init__(win, x, y, width, height, **kwargs)  # Initialize parent slider class
        self.vertical = False  # Set slider orientation
        self.font = font  # Store font for text labels
        # Render min and max text labels
        self.min_text = [self.font.render(x, False, self.COLOR) for x in kwargs.get('min_text')]
        self.max_text = [self.font.render(x, False, self.COLOR) for x in kwargs.get('max_text')]
        self.heightSlider = self.getHeight()  # Get the height of the slider
        # Adjust height to accommodate text labels
        self.setHeight(self.getHeight() + max(self.min_text[0].get_height() * len(self.min_text),
                                              self.max_text[0].get_height() * len(self.max_text)))

    def draw(self):  # Draw the slider
        if not self._hidden:  # Check if the slider is visible
            # Draw the slider bar
            pygame.draw.rect(self.win, self.colour,
                             (self._x, self._y, self._width, self.heightSlider))

            if self.curved:  # If the slider has curved ends
                pygame.draw.circle(self.win, self.colour,
                                   (self._x, self._y + self.heightSlider // 2),
                                   self.radius)  # Draw left curve
                pygame.draw.circle(self.win, self.colour,
                                   (self._x + self._width, self._y + self.heightSlider // 2),
                                   self.radius)  # Draw right curve

            circle = (int(self._x + (self.value - self.min) / (self.max - self.min) * self._width),
                      self._y + self.heightSlider // 2)  # Calculate the position of the slider handle

            gfxdraw.filled_circle(self.win, *circle, self.handleRadius,
                                  self.handleColour)  # Draw filled handle
            gfxdraw.aacircle(self.win, *circle, self.handleRadius,
                             self.handleColour)  # Draw outline of handle

            text_height_sum = 0  # Initialize height for min text
            for text in self.min_text:  # Draw min labels
                text_height_sum += text.get_height()  # Accumulate height
                text_rect = text.get_rect()
                text_rect.center = (self._x,
                                    self._y + self.heightSlider + text_height_sum)  # Center text
                self.win.blit(text, text_rect)  # Draw min label

            text_height_sum = 0  # Initialize height for max text
            for text in self.max_text:  # Draw max labels
                text_height_sum += text.get_height()  # Accumulate height
                text_rect = text.get_rect()
                text_rect.center = (
                    self._x + self.getWidth(),
                    self._y + self.heightSlider + text_height_sum)  # Center text
                self.win.blit(text, text_rect)  # Draw max label

    def contains(self, x, y):  # Check if the point is within the slider
        handleX = int(
            self._x + (self.value - self.min) /
            (self.max - self.min) * self._width)  # Calculate handle position
        handleY = self._y + self.heightSlider // 2  # Calculate vertical position

        # Check distance
        if math.sqrt((handleX - x) ** 2 + (handleY - y) ** 2) <= self.handleRadius:
            return True  # Return True if inside

        return False  # Return False if outside


class LogarithmicSlider(pygame_widgets.slider.Slider):  # Class to create logarithmic sliders
    COLOR = "#d9d9d9"  # Color constant for the logarithmic slider

    def __init__(self, win, x, y, width, height, font, exp_base, **kwargs):
        super().__init__(win, x, y, width, height, **kwargs)  # Initialize parent class
        self.vertical = False  # Set slider orientation
        self.exp_base = exp_base  # Store base for logarithmic calculations
        self.min_log_val = math.log(self.min, self.exp_base)  # Calculate logarithmic min value
        self.max_log_val = math.log(self.max, self.exp_base)  # Calculate logarithmic max value
        self.scale = (self.max_log_val - self.min_log_val) / width  # Calculate scale factor
        self.value = math.pow(self.exp_base, (self.max_log_val + self.min_log_val) / 2)  # Set initial value
        self.font = font  # Store font for text labels
        # Render min and max text labels
        self.min_text = [self.font.render(x, False, self.COLOR) for x in kwargs.get('min_text')]
        self.max_text = [self.font.render(x, False, self.COLOR) for x in kwargs.get('max_text')]
        self.heightSlider = self.getHeight()  # Get the height of the slider
        # Adjust height to accommodate text labels
        self.setHeight(self.getHeight() + max(self.min_text[0].get_height() * len(self.min_text),
                                              self.max_text[0].get_height() * len(self.max_text)))

    def val_from_pos(self, position):  # Convert position to value
        return math.pow(self.exp_base, position * self.scale + self.min_log_val)  # Calculate value

    def pos_from_val(self, value):  # Convert value to position
        return (math.log(value, self.exp_base) - self.min_log_val) / self.scale  # Calculate position

    def listen(self, events):  # Listen for mouse events
        if not self._hidden and not self._disabled:  # Check if visible and not disabled
            mouseState = Mouse.getMouseState()  # Get mouse state
            x, y = Mouse.getMousePos()  # Get mouse position

            if self.contains(x, y):  # Check if mouse is over the slider
                if mouseState == MouseState.CLICK:  # If clicked
                    self.selected = True  # Mark as selected

            if mouseState == MouseState.RELEASE:  # If mouse is released
                self.selected = False  # Deselect

            if self.selected:  # If selected
                self.value = self.val_from_pos((x - self._x))  # Update value based on position
                self.value = max(min(self.value, self.max), self.min)  # Clamp value within range

    def draw(self):  # Draw the logarithmic slider
        if not self._hidden:  # Check if visible
            # Draw slider bar
            pygame.draw.rect(self.win, self.colour,
                             (self._x, self._y, self._width, self.heightSlider))

            if self.curved:  # If the slider has curved ends
                pygame.draw.circle(self.win, self.colour,
                                   (self._x, self._y + self.heightSlider // 2),
                                   self.radius)  # Draw left curve
                pygame.draw.circle(self.win, self.colour,
                                   (self._x + self._width,
                                    self._y + self.heightSlider // 2),
                                   self.radius)  # Draw right curve

            # Calculate handle position
            circle = (int(self._x + self.pos_from_val(self.value)),
                      self._y + self.heightSlider // 2)

            gfxdraw.filled_circle(self.win, *circle,
                                  self.handleRadius, self.handleColour)  # Draw filled handle
            gfxdraw.aacircle(self.win, *circle,
                             self.handleRadius, self.handleColour)  # Draw outline of handle

            text_height_sum = 0  # Initialize height for min text
            for text in self.min_text:  # Draw min labels
                text_height_sum += text.get_height()  # Accumulate height
                text_rect = text.get_rect()
                # Center text
                text_rect.center = (self._x,
                                    self._y + self.heightSlider + text_height_sum)
                self.win.blit(text, text_rect)  # Draw min label

            text_height_sum = 0  # Initialize height for max text
            for text in self.max_text:  # Draw max labels
                text_height_sum += text.get_height()  # Accumulate height
                text_rect = text.get_rect()
                # Center text
                text_rect.center = (
                    self._x + self.getWidth(),
                    self._y + self.heightSlider + text_height_sum)
                self.win.blit(text, text_rect)  # Draw max label

    def contains(self, x, y):  # Check if a point(x,y) is within the slider
        # Calculate handle horizontal position
        handleX = int(self._x +
                      (math.log(self.value, self.exp_base) -
                       math.log(self.min, self.exp_base)) / self.scale)
        # Calculate handle vertical position
        handleY = self._y + self.heightSlider // 2

        if math.sqrt((handleX - x) ** 2 + (handleY - y) ** 2) <= self.handleRadius:  # Check distance
            return True  # Return True if inside

        return False  # Return False if outside


class TextBox(pygame_widgets.textbox.TextBox):  # Class to create a customizable text box
    def __init__(self, win, x, y, width, height, **kwargs):
        super().__init__(win, x, y, width, height, **kwargs)  # Initialize parent class
        self.textOffsetBottom = self.fontSize // 6  # Offset for text from the bottom
        self.textOffsetLeft = self.fontSize // 6  # Offset for text from the left

    def draw(self):  # Method to draw the text box
        """ Display to surface """
        if not self._hidden:  # Check if the text box is visible
            if self.selected:  # If the text box is selected
                self.updateCursor()  # Update the cursor position

            # Define rectangles and circles for the border and background
            borderRects = [
                (self._x + self.radius, self._y, self._width - self.radius * 2, self._height),  # Top border
                (self._x, self._y + self.radius, self._width, self._height - self.radius * 2),  # Left border
            ]

            borderCircles = [  # Corner circles for the border
                (self._x + self.radius, self._y + self.radius),
                (self._x + self.radius, self._y + self._height - self.radius),
                (self._x + self._width - self.radius, self._y + self.radius),
                (self._x + self._width - self.radius, self._y + self._height - self.radius)
            ]

            backgroundRects = [  # Background rectangles
                (
                    self._x + self.borderThickness + self.radius,
                    self._y + self.borderThickness,
                    self._width - 2 * (self.borderThickness + self.radius),
                    self._height - 2 * self.borderThickness
                ),
                (
                    self._x + self.borderThickness,
                    self._y + self.borderThickness + self.radius,
                    self._width - 2 * self.borderThickness,
                    self._height - 2 * (self.borderThickness + self.radius)
                )
            ]

            backgroundCircles = [  # Background circles for corners
                (self._x + self.radius + self.borderThickness,
                 self._y + self.radius + self.borderThickness),
                (self._x + self.radius + self.borderThickness,
                 self._y + self._height - self.radius - self.borderThickness),
                (self._x + self._width - self.radius - self.borderThickness,
                 self._y + self.radius + self.borderThickness),
                (self._x + self._width - self.radius - self.borderThickness,
                 self._y + self._height - self.radius - self.borderThickness)
            ]

            # Draw borders
            for rect in borderRects:
                pygame.draw.rect(self.win, self.borderColour, rect)  # Draw border rectangles

            for circle in borderCircles:
                pygame.draw.circle(self.win, self.borderColour, circle, self.radius)  # Draw border circles

            # Draw background
            for rect in backgroundRects:
                pygame.draw.rect(self.win, self.colour, rect)  # Draw background rectangles

            for circle in backgroundCircles:
                pygame.draw.circle(self.win, self.colour, circle, self.radius)  # Draw background circles

            # Display text or placeholder text
            x = [self._x + self.textOffsetLeft]  # Initialize x position for text
            for c in (self.text if len(self.text) > 0 else self.placeholderText):  # Choose between text and placeholder
                text = self.font.render(c, False,
                                        (self.textColour if len(
                                            self.text) > 0 else self.placeholderTextColour))  # Render the character
                textRect = text.get_rect(
                    bottomleft=(x[-1], self._y + self._height - self.textOffsetBottom))  # Position the text
                self.win.blit(text, textRect)  # Draw the text on the screen
                x.append(x[-1] + text.get_width())  # Update x position for the next character

            # Draw the cursor if it should be shown
            if self.showCursor:
                try:
                    pygame.draw.line(
                        self.win, self.cursorColour,
                        (x[self.cursorPosition], self._y + self.cursorOffsetTop),  # Start point of the cursor line
                        (x[self.cursorPosition], self._y + self._height - self.cursorOffsetTop)
                        # End point of the cursor line
                    )
                except IndexError:
                    self.cursorPosition -= 1  # Adjust cursor position on index error

            # Check if the maximum length of the text has been reached
            if x[-1] > self._x + self._width - self.textOffsetRight:
                self.maxLengthReached = True  # Set flag if max length is reached
