import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/market_state.dart';
import '../engines/pricing_engine.dart';

class StrategyBuilderScreen extends HookConsumerWidget {
  const StrategyBuilderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legs = useState<List<OptionContract>>([]);
    
    double totalDelta = 0;
    double totalGamma = 0;
    double totalVega = 0;
    double totalTheta = 0;
    double totalPremium = 0;

    for (final leg in legs.value) {
      totalDelta += leg.greeks.delta;
      totalGamma += leg.greeks.gamma;
      totalVega += leg.greeks.vega;
      totalTheta += leg.greeks.theta;
      totalPremium += leg.greeks.premium;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Strategy Builder'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => legs.value = [],
          )
        ],
      ),
      body: Column(
        children: [
          _buildSummaryHeader(totalPremium, totalDelta, totalGamma, totalVega, totalTheta),
          Expanded(
            child: legs.value.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: legs.value.length,
                  itemBuilder: (context, index) {
                    final leg = legs.value[index];
                    return ListTile(
                      title: Text('${leg.type.name.toUpperCase()} ${leg.strike.toStringAsFixed(0)}'),
                      subtitle: Text('Premium: \$${leg.greeks.premium.toStringAsFixed(2)} | Δ: ${leg.greeks.delta.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        onPressed: () {
                          final newList = List<OptionContract>.from(legs.value);
                          newList.removeAt(index);
                          legs.value = newList;
                        },
                      ),
                    );
                  },
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _showAddLegSelector(context, ref, legs),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('ADD LEG'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(double premium, double d, double g, double v, double t) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1E2329),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Cost/Credit', style: TextStyle(color: Colors.white54)),
              Text('\$${premium.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFF0B90B))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _greekMini('Δ', d),
              _greekMini('Γ', g),
              _greekMini('V', v),
              _greekMini('Θ', t),
            ],
          )
        ],
      ),
    );
  }

  Widget _greekMini(String label, double val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        Text(val.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.architecture, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text('Build Multi-leg Strategies', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  void _showAddLegSelector(BuildContext context, WidgetRef ref, ValueNotifier<List<OptionContract>> legs) {
    final chain = ref.read(optionsChainProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2329),
      builder: (context) => ListView.builder(
        itemCount: chain.length,
        itemBuilder: (context, index) {
          final contract = chain[index];
          return ListTile(
            title: Text('${contract.type.name.toUpperCase()} ${contract.strike.toStringAsFixed(0)}'),
            trailing: Text('\$${contract.greeks.premium.toStringAsFixed(2)}'),
            onTap: () {
              legs.value = [...legs.value, contract];
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
