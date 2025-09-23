from producto import Producto
class ProductoNoEncontradoError(Exception):
    pass
    
class Tienda:
    def __init__(self):
        self.inventario = []
    def agregar_producto(self, producto):
        self.inventario.append(producto)
    def buscar_producto(self, nombre):
        for producto in self.inventario:
            if producto.nombre == nombre:
                return producto
        raise ProductoNoEncontradoError(f"Producto '{nombre}' no encontrado.")
        #return None
    def eliminar_producto(self, nombre):
        for producto in self.inventario:
            if producto.nombre == nombre:
                self.inventario.remove(producto)
                return True
        raise ProductoNoEncontradoError(f"No se puede eliminar '{nombre}': producto no existe.")
        #return False
    def aplicar_descuento(self, nombre: str, porcentaje: float):
        if not (0 <= porcentaje <= 100):
            raise ValueError("El porcentaje de descuento debe estar entre 0 y 100.")
        producto = self.buscar_producto(nombre) 
        descuento = producto.precio * (porcentaje / 100)
        producto.actualizar_precio(producto.precio - descuento)
    
    def calcular_total_carrito(self, carrito: list[str]) -> float:
        total = 0.0
        for nombre_producto in carrito:
            try:
                producto = self.buscar_producto(nombre_producto)
                total += producto.precio
            except ProductoNoEncontradoError:
                print(f"Advertencia: El producto '{nombre_producto}' no se encontró en el inventario y no se incluyó en el total.")
                continue
        return total
    