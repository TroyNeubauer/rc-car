from setuptools import setup

setup(
    name="god",
    version="0.1.0",
    packages=["god"],
    entry_points={
        "console_scripts": [
            "god = god.main:main",
        ],
    },
)

