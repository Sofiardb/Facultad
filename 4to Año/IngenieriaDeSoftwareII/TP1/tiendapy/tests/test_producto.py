
import pytest
from producto import Producto

def test_crear_producto_valido():
    p = Producto("Camiseta", 19.99, "Ropa")
    assert p.nombre == "Camiseta"
    assert p.precio == 19.99
    assert p.categoria == "Ropa"

def test_crear_producto_precio_negativo_lanza_excepcion():
    with pytest.raises(ValueError):
        Producto("Mug", -5.0, "Utiles")

def test_actualizar_precio_valido():
    p = Producto("Zapatillas", 50.0, "Calzado")
    p.actualizar_precio(45.0)
    assert p.precio == 45.0

def test_actualizar_precio_negativo_lanza_excepcion():
    p = Producto("Gorra", 10.0, "Accesorios")
    with pytest.raises(ValueError):
        p.actualizar_precio(-1.0)
