import pygame  # Import Pygame for game development


class MenuGroup():  # Class to manage a group of menu items (sliders)
    def __init__(self, *args):
        self.sliders = list(args)  # Initialize the sliders list with provided arguments

    def append(self, *args):  # Method to add new sliders to the group
        for i in args:  # Loop through each argument
            self.sliders.append(i)  # Append the slider to the list

    def hide(self):  # Method to hide all sliders in the group
        for slider in self.sliders:  # Loop through each slider
            slider.hide()  # Call the hide method on the slider

    def show(self):  # Method to show all sliders in the group
        for slider in self.sliders:  # Loop through each slider
            slider.show()  # Call the show method on the slider