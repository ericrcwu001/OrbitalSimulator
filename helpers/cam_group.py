import pygame  # Import Pygame for game development


class CamGroup(pygame.sprite.Group):  # Class to manage camera movements
    def __init__(self):
        super().__init__()  # Initialize the parent sprite group
        self.offset = pygame.math.Vector2()  # Initialize offset for camera position
        self.clickstart_offset = pygame.math.Vector2()  # Offset when clicking to drag
        self.dragging = False  # Flag to track if dragging is happening
        self.reset_scales()  # Reset camera scales and offsets

    def reset_scales(self):  # Method to reset camera position and scale
        self.offset.x = 0  # Reset x offset
        self.offset.y = 0  # Reset y offset
        self.scale_size = 0.6  # Set default scale size

    def check_collision(self, event):  # Method to handle mouse events for dragging
        mouse_x, mouse_y = pygame.mouse.get_pos()  # Get current mouse position
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:  # If left mouse button is pressed
            self.dragging = True  # Start dragging
            self.clickstart_offset.x = self.offset.x - mouse_x  # Calculate x offset for dragging
            self.clickstart_offset.y = self.offset.y - mouse_y  # Calculate y offset for dragging

        elif event.type == pygame.MOUSEBUTTONUP and event.button == 1:  # If left mouse button is released
            self.dragging = False  # Stop dragging

        elif event.type == pygame.MOUSEMOTION:  # If the mouse is moved
            if self.dragging:  # If dragging is active
                self.offset.x = mouse_x + self.clickstart_offset.x  # Update x offset
                self.offset.y = mouse_y + self.clickstart_offset.y  # Update y offset

        elif event.type == pygame.KEYDOWN and event.key == pygame.K_SPACE:  # If space key is pressed
            self.reset_scales()  # Reset camera scales

        return True  # Return True to indicate event was handled