import 'package:flutter/material.dart';

import 'actividad_record.dart';
import 'historial_provider.dart';

/// Tarjeta de "Evolución de Fluidez": deja al tutor elegir un tipo de
/// actividad (para comparar solo cosas iguales entre sí) y ver cómo ha
/// cambiado el tiempo que tarda el niño, tanto en los últimos N ejercicios
/// como semana contra semana.
class FluidezCard extends StatefulWidget {
  final List<ActividadRecord> historial;
  final Color primaryColor;

  const FluidezCard({super.key, required this.historial, required this.primaryColor});

  @override
  State<FluidezCard> createState() => _FluidezCardState();
}

class _FluidezCardState extends State<FluidezCard> {
  String _tipo = 'pictograma';
  int _cantidad = 10;

  static const Map<String, String> _tiposDisponibles = {
    'pictograma': 'Pictogramas',
    'letra': 'Letras',
    'cuento': 'Cuentos',
  };

  static const List<int> _opcionesCantidad = [10, 20, 40];

  @override
  Widget build(BuildContext context) {
    final actividadesTipo = HistorialMetrics.porTipo(widget.historial, _tipo);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Evolución de Fluidez', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Cuánto tarda el niño en resolver, comparando solo el mismo tipo de actividad.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            _buildSelectorTipo(),
            const SizedBox(height: 20),
            if (actividadesTipo.isEmpty)
              _buildSinDatos()
            else ...[
              _buildSelectorCantidad(actividadesTipo.length),
              const SizedBox(height: 16),
              _buildGrafico(actividadesTipo),
              const SizedBox(height: 16),
              _buildResumenTendencia(actividadesTipo),
              const Divider(height: 32),
              _buildComparacionSemanal(actividadesTipo),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSinDatos() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Aún no hay actividades de tipo "${_tiposDisponibles[_tipo]}".',
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildSelectorTipo() {
    return Wrap(
      spacing: 8,
      children: _tiposDisponibles.entries.map((entry) {
        final seleccionado = _tipo == entry.key;
        return ChoiceChip(
          label: Text(entry.value),
          selected: seleccionado,
          onSelected: (_) => setState(() => _tipo = entry.key),
          selectedColor: widget.primaryColor.withOpacity(0.2),
          labelStyle: TextStyle(
            color: seleccionado ? widget.primaryColor : Colors.black87,
            fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectorCantidad(int totalDisponible) {
    return Row(
      children: [
        Text('Ver últimos:', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        const SizedBox(width: 8),
        Wrap(
          spacing: 6,
          children: _opcionesCantidad.map((n) {
            final seleccionado = _cantidad == n;
            // No mostramos una opción si ni siquiera hay esa cantidad de
            // datos, salvo la más chica (10), que siempre mostramos como
            // referencia aunque haya menos actividades que eso.
            if (n != _opcionesCantidad.first && totalDisponible < n) {
              return const SizedBox.shrink();
            }
            return GestureDetector(
              onTap: () => setState(() => _cantidad = n),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: seleccionado ? widget.primaryColor : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$n',
                  style: TextStyle(
                    fontSize: 12,
                    color: seleccionado ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGrafico(List<ActividadRecord> actividadesTipo) {
    // `actividadesTipo` viene ordenado del más reciente al más antiguo
    // (así sale del historialProvider). Tomamos los últimos N y los damos
    // vuelta para dibujar el gráfico en orden cronológico (izquierda =
    // más antiguo, derecha = más reciente), que es como se lee un progreso.
    final muestra = actividadesTipo.take(_cantidad).toList().reversed.toList();
    final maxSegundos = muestra.map((a) => a.duracion.inSeconds).fold<int>(1, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 110,
      child: LayoutBuilder(builder: (context, constraints) {
        final anchoBarra = (constraints.maxWidth / muestra.length).clamp(6.0, 36.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: muestra.map((a) {
            final segundos = a.duracion.inSeconds;
            final alturaRelativa = (segundos / maxSegundos).clamp(0.05, 1.0);
            return Tooltip(
              message: '${segundos}s',
              child: Container(
                width: anchoBarra,
                height: 90 * alturaRelativa,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withOpacity(0.75),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildResumenTendencia(List<ActividadRecord> actividadesTipo) {
    final muestra = actividadesTipo.take(_cantidad).toList().reversed.toList();

    // Con muy pocos datos, cualquier "tendencia" es más ruido que señal.
    // Preferimos decirlo claramente en vez de mostrar un porcentaje que
    // parece más confiable de lo que realmente es.
    if (muestra.length < 4) {
      return Text(
        'Necesitas al menos 4 ejercicios de este tipo para ver una tendencia confiable.',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
      );
    }

    final mitad = (muestra.length / 2).ceil();
    final primeraMitad = muestra.take(mitad).toList();
    final segundaMitad = muestra.skip(mitad).toList();

    final promedioAntes = HistorialMetrics.duracionPromedioSegundos(primeraMitad);
    final promedioAhora = HistorialMetrics.duracionPromedioSegundos(segundaMitad);

    if (promedioAntes == 0) return const SizedBox.shrink();

    final cambio = ((promedioAntes - promedioAhora) / promedioAntes * 100).round();
    final mejorando = cambio > 0;

    return Row(
      children: [
        Icon(
          mejorando ? Icons.trending_down_rounded : Icons.trending_up_rounded,
          color: mejorando ? Colors.green : Colors.orange.shade700,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            mejorando
                ? '${cambio.abs()}% más rápido que al inicio de esta muestra (de ${promedioAntes.round()}s a ${promedioAhora.round()}s en promedio)'
                : 'Ahora tarda ${cambio.abs()}% más que al inicio de esta muestra — puede ser normal si el nivel subió de dificultad',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildComparacionSemanal(List<ActividadRecord> actividadesTipo) {
    final estaSemana = HistorialMetrics.ultimaSemana(actividadesTipo);
    final semanaPasada = HistorialMetrics.semanaAnterior(actividadesTipo);

    if (estaSemana.isEmpty && semanaPasada.isEmpty) {
      return Text(
        'Sin actividades de este tipo en las últimas 2 semanas.',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      );
    }

    final promEstaSemana = HistorialMetrics.duracionPromedioSegundos(estaSemana);
    final promSemanaPasada = HistorialMetrics.duracionPromedioSegundos(semanaPasada);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Semana vs. semana', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _filaComparacion('Semana pasada', semanaPasada.length, promSemanaPasada),
        const SizedBox(height: 4),
        _filaComparacion('Esta semana', estaSemana.length, promEstaSemana),
      ],
    );
  }

  Widget _filaComparacion(String etiqueta, int cantidad, double promedioSegundos) {
    final texto = cantidad == 0 ? 'Sin datos' : '$cantidad ejercicio${cantidad == 1 ? '' : 's'} · ${promedioSegundos.round()}s promedio';
    return Row(
      children: [
        SizedBox(width: 110, child: Text(etiqueta, style: const TextStyle(fontSize: 13))),
        Expanded(child: Text(texto, style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
      ],
    );
  }
}
