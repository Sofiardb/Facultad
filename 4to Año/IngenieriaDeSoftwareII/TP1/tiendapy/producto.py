class Producto:
    def __init__(self, nombre, precio, categoria):
        if precio <= 0:
            raise ValueError("El precio no puede ser negativo")
        self.nombre = nombre
        self.precio = precio
        self.categoria = categoria

    def actualizar_precio(self, nuevo_precio: float) -> None:
        if nuevo_precio <= 0:
            raise ValueError("El nuevo precio no puede ser negativo")
        self.precio = nuevo_precio
    