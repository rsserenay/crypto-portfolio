import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/coin_model.dart';
import '../../controllers/portfolio_controller.dart';
import '../../theme/app_colors.dart';

/// Satın alırken / satarken kullanıcı iki moddan birini seçebilir:
/// - amount: "kaç adet" (örn: 0.5 BTC)
/// - currency: "kaç dolarlık/liralık" (örn: 200$'lık)
enum _BuyInputMode { amount, currency }

/// Coine tıklandığında açılan satın alma / satış formu.
/// Kendi başına hesaplama yapmaz; işlemi PortfolioController'a devreder.
/// Satış modunda ayrıca anlık kâr/zarar önizlemesi gösterir.
class BuySheet extends StatefulWidget {
  final CoinModel coin;
  final bool isSelling;

  const BuySheet({
    super.key,
    required this.coin,
    this.isSelling = false,
  });

  @override
  State<BuySheet> createState() => _BuySheetState();
}

class _BuySheetState extends State<BuySheet> {
  final TextEditingController _amountController = TextEditingController();

  _BuyInputMode _mode = _BuyInputMode.amount;

  static const List<double> _quickCurrencyAmounts = [50, 100, 200, 500];

  late final PortfolioController _portfolioController;

  @override
  void initState() {
    super.initState();
    _portfolioController = Get.find<PortfolioController>();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Kullanıcının şu an bu coinden sahip olduğu adet + ortalama alış fiyatı.
  double get _ownedAmount =>
      _portfolioController.holdings[widget.coin.id]?.amount ?? 0;

  double get _avgBuyPrice =>
      _portfolioController.holdings[widget.coin.id]?.avgBuyPrice ?? 0;

  /// Girilen metni yorumlayıp coin adedine çevirir (önizleme için).
  double? get _estimatedCoinAmount {
    final raw = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (raw == null || raw <= 0) return null;

    if (_mode == _BuyInputMode.currency) {
      if (widget.coin.currentPrice <= 0) return null;
      return raw / widget.coin.currentPrice;
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelling = widget.isSelling;
    final double currentPrice = widget.coin.currentPrice;

    // Genel (mevcut pozisyon) kâr/zarar - satış ekranında üstte özet olarak.
    final double ownedValueUsd = _ownedAmount * currentPrice;
    final double ownedInvestedUsd = _ownedAmount * _avgBuyPrice;
    final double ownedProfitUsd = ownedValueUsd - ownedInvestedUsd;
    final double ownedProfitPct =
        ownedInvestedUsd > 0 ? (ownedProfitUsd / ownedInvestedUsd) * 100 : 0;

    // Girilen miktara göre BU satıştan doğacak kâr/zarar önizlemesi.
    final double? previewAmount = isSelling ? _estimatedCoinAmount : null;
    final double? previewProceeds =
        previewAmount != null ? previewAmount * currentPrice : null;
    final double? previewInvested =
        previewAmount != null ? previewAmount * _avgBuyPrice : null;
    final double? previewProfit =
        (previewProceeds != null && previewInvested != null)
            ? previewProceeds - previewInvested
            : null;
    final double? previewProfitPct = (previewProfit != null &&
            previewInvested != null &&
            previewInvested > 0)
        ? (previewProfit / previewInvested) * 100
        : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.coin.image.isNotEmpty
                    ? NetworkImage(widget.coin.image)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                isSelling ? 'Coin Sat' : 'Coin Satın Al',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Güncel Fiyat: \$${currentPrice.toStringAsFixed(4)}',
            style: TextStyle(color: Colors.grey.shade600),
          ),

          // --- SATIŞ ÖZETİ: elimde ne kadar var, şu an ne kâr/zarardayım ---
          if (isSelling) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sahip Olduğun',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${_ownedAmount.toStringAsFixed(6)} ${widget.coin.symbol}  '
                          '(~\$${ownedValueUsd.toStringAsFixed(2)})',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ortalama Alış',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '\$${_avgBuyPrice.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Güncel Kâr/Zarar',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${ownedProfitUsd >= 0 ? '+' : ''}\$${ownedProfitUsd.toStringAsFixed(2)} '
                        '(${ownedProfitUsd >= 0 ? '+' : ''}${ownedProfitPct.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ownedProfitUsd >= 0
                              ? AppColors.positive
                              : AppColors.negative,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_ownedAmount > 0) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _amountController.text = _mode == _BuyInputMode.currency
                          ? ownedValueUsd.toStringAsFixed(2)
                          : _ownedAmount.toStringAsFixed(8);
                    });
                  },
                  icon: const Icon(Icons.select_all, size: 16),
                  label: const Text('Tümünü Sat'),
                ),
              ),
            ],
          ],

          const SizedBox(height: 16),

          // Adet / Tutar seçimi (hem alışta hem satışta kullanılabilir)
          SegmentedButton<_BuyInputMode>(
            segments: const [
              ButtonSegment(
                value: _BuyInputMode.amount,
                label: Text('Adet ile'),
                icon: Icon(Icons.tag),
              ),
              ButtonSegment(
                value: _BuyInputMode.currency,
                label: Text('Tutar ile (\$)'),
                icon: Icon(Icons.attach_money),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) {
              setState(() {
                _mode = selection.first;
                _amountController.clear();
              });
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: AppColors.textOnDark,
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText:
                  _mode == _BuyInputMode.currency ? 'Tutar (\$)' : 'Adet',
              border: const OutlineInputBorder(),
              hintText:
                  _mode == _BuyInputMode.currency ? 'Örn: 200' : 'Örn: 0.5',
              prefixText: _mode == _BuyInputMode.currency ? '\$ ' : null,
            ),
          ),

          // Sahip olunandan fazla satış girilirse anında uyar.
          if (isSelling &&
              _estimatedCoinAmount != null &&
              _estimatedCoinAmount! > _ownedAmount + 0.00000001) ...[
            const SizedBox(height: 8),
            Text(
              'En fazla ${_ownedAmount.toStringAsFixed(6)} ${widget.coin.symbol} '
              '(~\$${ownedValueUsd.toStringAsFixed(2)}) satabilirsin.',
              style: const TextStyle(
                color: AppColors.negative,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          if (_mode == _BuyInputMode.currency) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _quickCurrencyAmounts.map((value) {
                return ActionChip(
                  label: Text('\$${value.toStringAsFixed(0)}'),
                  backgroundColor: AppColors.chipUnselected,
                  onPressed: () {
                    setState(() {
                      _amountController.text = value.toStringAsFixed(0);
                    });
                  },
                );
              }).toList(),
            ),
          ],

          // --- ALIŞ ÖNİZLEMESİ: kaç coin alacaksın / kaç dolar tutuyor ---
          if (!isSelling && _estimatedCoinAmount != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.chipUnselected,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _mode == _BuyInputMode.currency
                    ? '≈ ${_estimatedCoinAmount!.toStringAsFixed(6)} ${widget.coin.symbol}'
                    : '≈ \$${(_estimatedCoinAmount! * currentPrice).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          // --- SATIŞ ÖNİZLEMESİ: bu satıştan ne kadar alacaksın, kâr/zararın ne olacak ---
          if (isSelling &&
              previewProceeds != null &&
              previewProfit != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (previewProfit >= 0
                        ? AppColors.positiveSoft
                        : AppColors.negativeSoft)
                    .withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: previewProfit >= 0
                      ? AppColors.positive
                      : AppColors.negative,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bu satıştan eline geçecek: \$${previewProceeds.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bu satıştan kâr/zararın: '
                    '${previewProfit >= 0 ? '+' : ''}\$${previewProfit.toStringAsFixed(2)}'
                    '${previewProfitPct != null ? ' (${previewProfit >= 0 ? '+' : ''}${previewProfitPct.toStringAsFixed(2)}%)' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: previewProfit >= 0
                          ? AppColors.positive
                          : AppColors.negative,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final double? inputValue = double.tryParse(
                  _amountController.text.replaceAll(',', '.'),
                );

                if (inputValue == null || inputValue <= 0) {
                  Get.snackbar(
                    'Hata',
                    'Geçerli bir miktar girin',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }

                final bool isCurrencyAmount = _mode == _BuyInputMode.currency;

                final success = isSelling
                    ? _portfolioController.sellCoin(
                        widget.coin.id,
                        inputValue,
                        isCurrencyAmount: isCurrencyAmount,
                      )
                    : _portfolioController.buyCoin(
                        widget.coin.id,
                        inputValue,
                        isCurrencyAmount: isCurrencyAmount,
                      );

                if (success) {
                  Get.back();

                  Get.snackbar(
                    'Başarılı',
                    isSelling
                        ? '${widget.coin.symbol} satıldı'
                        : '${widget.coin.symbol} portföyüne eklendi',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } else {
                  Get.snackbar(
                    'Hata',
                    isSelling
                        ? 'Sahip olduğunuz miktardan fazla satamazsınız.'
                        : 'Coin fiyat bilgisi henüz yüklenmedi.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(isSelling ? 'Coin Sat' : 'Coin Satın Al'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}