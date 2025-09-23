
import pytest
from unittest.mock import Mock
from tienda import Tienda, ProductoNoEncontradoError
from producto import Producto

def test_agregar_producto_y_verificar_en_tienda():
    tienda = Tienda()
    p = Producto("Laptop", 999.99, "Tecnología")
    tienda.agregar_producto(p)
    assert any(prod.nombre == "Laptop" for prod in tienda.inventario)

def test_buscar_producto_existente():
    tienda = Tienda()
    p = Producto("Teclado", 29.99, "Tecnología")
    tienda.agregar_producto(p)
    encontrado = tienda.buscar_producto("Teclado")
    assert encontrado is not None
    assert isinstance(encontrado, Producto) and encontrado.nombre == "Teclado"


def test_buscar_producto_no_existente():
    tienda = Tienda()
    with pytest.raises(ProductoNoEncontradoError):
        tienda.buscar_producto("Ratón Inalámbrico")
    #assert encontrado is None

def test_eliminar_producto_existente():
    tienda = Tienda()
    p = Producto("Monitor", 199.99, "Tecnología")
    tienda.agregar_producto(p)
    eliminado = tienda.eliminar_producto("Monitor")
    assert eliminado is True
    with pytest.raises(ProductoNoEncontradoError):
        tienda.buscar_producto("Monitor")
    #assert tienda.buscar_producto("Monitor") is None

def test_eliminar_producto_no_existente():
    tienda = Tienda()
    with pytest.raises(ProductoNoEncontradoError):
        tienda.eliminar_producto("Teclado Mecánico")
    #assert eliminado is False


def test_aplicar_descuento_valido():
    tienda = Tienda()

    #Crea un mock de producto
    producto_mock = Mock()
    producto_mock.nombre = "Laptop"
    producto_mock.precio = 1000.0
    producto_mock.categoria = "Tecnología"

    #Crea un mock del método para no probar la implementación real del método sino que registra llamadas
    producto_mock.actualizar_precio = Mock()

    tienda.inventario.append(producto_mock)

    tienda.aplicar_descuento("Laptop", 10)

    #Verifico que el método llame correctamente a actualizar_precio de producto con el argumento correspondiente.
    producto_mock.actualizar_precio.assert_called_once_with(900.0)

def test_aplicar_descuento_invalido():
    tienda = Tienda()
    '''
    #Crea un mock de producto
    producto_mock = Mock()
    producto_mock.nombre = "Laptop"
    producto_mock.precio = 1000.0
    producto_mock.categoria = "Tecnología"

    #Crea un mock del método para no probar la implementación real del método sino que registra llamadas
    producto_mock.actualizar_precio = Mock()

    tienda.inventario.append(producto_mock)
    '''
    with pytest.raises(ValueError):
        tienda.aplicar_descuento("Laptop", -10)
    #Verifico que el método llame correctamente a actualizar_precio de producto con el argumento correspondiente.
    #producto_mock.actualizar_precio.assert_called_once_with(900.0)

# Debería hacer un test para aplicar descuento de un producto que no existe? El control de que no existe lo hace una función ya probada antes


@pytest.fixture
def tienda_con_productos_fixture():
    """Un fixture que configura una instancia de Tienda con productos para la prueba."""
    tienda = Tienda()
    tienda.agregar_producto(Producto("Placa de video", 999.99, "Tecnología"))
    tienda.agregar_producto(Producto("Teclado", 29.99, "Tecnología"))
    tienda.agregar_producto(Producto("Monitor", 199.99, "Tecnología"))
    return tienda

def test_agregar_producto_y_verificar_en_tienda_fix(tienda_con_productos_fixture):
    p = Producto("Laptop", 999.99, "Tecnología")
    tienda_con_productos_fixture.agregar_producto(p)
    assert any(prod.nombre == "Laptop" for prod in tienda_con_productos_fixture.inventario)


def test_buscar_producto_existente_fix(tienda_con_productos_fixture):
    encontrado = tienda_con_productos_fixture.buscar_producto("Teclado")
    assert encontrado is not None
    assert isinstance(encontrado, Producto)
    assert encontrado.nombre == "Teclado"

def test_buscar_producto_no_existente_fix(tienda_con_productos_fixture):
    with pytest.raises(ProductoNoEncontradoError):
        tienda_con_productos_fixture.buscar_producto("Ratón Inalámbrico")

def test_flujo_completo_calcular_total_con_descuento(tienda_con_productos_fixture):
    """
    Prueba de integración: verifica el flujo completo de aplicar un descuento
    y luego calcular correctamente el total del carrito.
    """
    tienda = tienda_con_productos_fixture

    nombre_producto = "Monitor"
    descuento_porcentaje = 10
    tienda.aplicar_descuento(nombre_producto, descuento_porcentaje)

    carrito = ["Placa de video", "Teclado", "Monitor"]

    total_final = tienda.calcular_total_carrito(carrito)

    precio_placa_video = 999.99
    precio_teclado = 29.99
    precio_monitor_con_descuento = 199.99 - 199.99 * (descuento_porcentaje / 100)
    
    total_esperado = precio_placa_video + precio_teclado + precio_monitor_con_descuento
    assert total_final == pytest.approx(total_esperado)

    print(f"Total calculado: {total_final}")
    print(f"Total esperado: {total_esperado}")