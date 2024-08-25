import pygame  # Import Pygame for game development


class PlanetGroup(pygame.sprite.Group):  # Class to manage a group of planet sprites
    def __init__(self, screen, *args, **kwargs):
        super().__init__()  # Initialize the parent sprite group
        self.screen = screen  # Store the reference to the screen
        self.updating = True  # Flag to control updating of planets
        self.name = "planet_group"  # Name of the group

    def set_updating(self, updating):  # Method to set the updating flag
        self.updating = updating  # Update the flag

    def update(self, *args, **kwargs):  # Method to update each planet in the group
        for sprite in self.sprites():  # Loop through all sprites in the group
            if self.updating:  # Check if updating is enabled
                sprite.draw(self.screen, 1, True, *args)  # Draw the planet
                sprite.update_position(self)  # Update the planet's position
            else:
                sprite.draw(self.screen, 1, True, *args)  # Just draw the planet without updating

    def check_collision(self, event):  # Method to check for collisions with drag events
        ret = [False, None]  # Initialize return values
        for sprite in self.sprites():  # Loop through all sprites
            if sprite.drag_planet(event):  # Check if the planet is being dragged
                ret[0] = True  # Set collision detected
                ret[1] = sprite  # Store the dragged sprite
        return ret  # Return the collision status and the sprite

    def unfocus(self):  # Method to unfocus all planets in the group
        for sprite in self.sprites():  # Loop through all sprites
            sprite.focused = False  # Set each sprite's focused state to False