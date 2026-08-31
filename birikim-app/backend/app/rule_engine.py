"""
Birikim Uygulaması — Kural Motoru (Rule Engine)

Bu modül, FastAPI endpoint'inden ayrı, saf (pure) fonksiyonlardan oluşur.
Neden ayrı: (1) unit test'i kolaylaştırır — HTTP/DB olmadan test edilebilir,
(2) "kuralları backend'de tut" ilkesini somutlaştırır — mobil taraf sadece
bu fonksiyonların ürettiği breakdown'ı gösterir.

İşlem sırası (önemli — sıra sonucu değiştirir):
    1. Öz-Vergi oranı belirlenir (kategori "guilty pleasure" ise çarpan uygulanır)
    2. Öz-Vergi tutarı = raw_amount * effective_rate
    3. Yuvarlama (round-up), öz-vergiden BAĞIMSIZ hesaplanır — ikisi ayrı
       birikim kaynaklarıdır ve kullanıcıya ayrı ayrı gösterilmelidir
       ("X TL öz-vergi + Y TL bozukluk" gibi), toplanıp tek kalemde eritilmez.

Tüm parasal değerler Decimal — asla float kullanılmaz.
"""

from dataclasses import dataclass
from decimal import ROUND_HALF_UP, Decimal
from datetime import datetime, timedelta, timezone
from typing import Optional


TWO_PLACES = Decimal("0.01")


def _q(value: Decimal) -> Decimal:
    """Parasal değerleri her zaman 2 ondalığa yuvarla."""
    return value.quantize(TWO_PLACES, rounding=ROUND_HALF_UP)


@dataclass(frozen=True)
class RuleSettings:
    self_tax_rate: Decimal            # örn. Decimal("0.10")
    roundup_enabled: bool
    roundup_unit: Decimal             # örn. Decimal("10.00")
    waiting_room_hours: int
    waiting_room_threshold: Decimal   # bu tutarın üstü Bekleme Odası'na girer


@dataclass(frozen=True)
class CategoryInfo:
    is_guilty_pleasure: bool
    penalty_multiplier: Decimal       # örn. Decimal("3.00")


@dataclass(frozen=True)
class TransactionBreakdown:
    raw_amount: Decimal
    effective_tax_rate: Decimal
    self_tax_amount: Decimal
    roundup_amount: Decimal
    total_diverted: Decimal


def calculate_effective_tax_rate(settings: RuleSettings, category: CategoryInfo) -> Decimal:
    """Zaaf Çarpanı yalnızca guilty-pleasure kategorilerde devreye girer."""
    if category.is_guilty_pleasure:
        return settings.self_tax_rate * category.penalty_multiplier
    return settings.self_tax_rate


def calculate_roundup(raw_amount: Decimal, settings: RuleSettings) -> Decimal:
    """En yakın üst birime tamamlar (Küsürat Yuvarlama)."""
    if not settings.roundup_enabled or settings.roundup_unit <= 0:
        return Decimal("0.00")

    unit = settings.roundup_unit
    remainder = raw_amount % unit
    if remainder == 0:
        return Decimal("0.00")
    return _q(unit - remainder)


def apply_rules(
    raw_amount: Decimal,
    settings: RuleSettings,
    category: CategoryInfo,
) -> TransactionBreakdown:
    """
    Bir harcamayı kural motorundan geçirir. Bu fonksiyon DB'ye yazmaz —
    sadece hesaplar. Sonucu transactions tablosuna yazmak çağıran kodun işi
    (bkz. örnek FastAPI endpoint'i en altta).
    """
    effective_rate = calculate_effective_tax_rate(settings, category)
    self_tax_amount = _q(raw_amount * effective_rate)
    roundup_amount = calculate_roundup(raw_amount, settings)
    total_diverted = _q(self_tax_amount + roundup_amount)

    return TransactionBreakdown(
        raw_amount=raw_amount,
        effective_tax_rate=effective_rate,
        self_tax_amount=self_tax_amount,
        roundup_amount=roundup_amount,
        total_diverted=total_diverted,
    )


def should_enter_waiting_room(raw_amount: Decimal, settings: RuleSettings) -> bool:
    """Bekleme Odası'na girmesi gereken dürtüsel harcama mı?"""
    return raw_amount >= settings.waiting_room_threshold


def waiting_room_expiry(settings: RuleSettings, now: Optional[datetime] = None) -> datetime:
    now = now or datetime.now(timezone.utc)
    return now + timedelta(hours=settings.waiting_room_hours)


def resolve_abandoned_purchase(amount: Decimal) -> Decimal:
    """
    Kullanıcı Bekleme Odası'ndaki bir harcamadan vazgeçerse, tutarın TAMAMI
    birikime eklenir (öz-vergi değil — vazgeçilen harcamanın kendisi).
    Bu, apply_rules'tan bilinçli olarak ayrı bir fonksiyon: farklı bir
    davranışsal olayı temsil ediyor (harcama değil, harcamama).
    """
    return _q(amount)


# ============================================================
# Örnek kullanım — FastAPI endpoint'i bu şekilde çağırır
# ============================================================
if __name__ == "__main__":
    settings = RuleSettings(
        self_tax_rate=Decimal("0.10"),
        roundup_enabled=True,
        roundup_unit=Decimal("10.00"),
        waiting_room_hours=24,
        waiting_room_threshold=Decimal("200.00"),
    )

    # Normal kategori (market alışverişi): 87.50 TL
    market = CategoryInfo(is_guilty_pleasure=False, penalty_multiplier=Decimal("1.00"))
    result = apply_rules(Decimal("87.50"), settings, market)
    print("Market:", result)
    # -> self_tax 8.75, roundup 2.50 (90'a tamamlama), toplam 11.25

    # Guilty pleasure (dışarıda yemek, 3x çarpan): 150.00 TL
    eating_out = CategoryInfo(is_guilty_pleasure=True, penalty_multiplier=Decimal("3.00"))
    result2 = apply_rules(Decimal("150.00"), settings, eating_out)
    print("Dışarıda yemek:", result2)
    # -> effective_rate 0.30, self_tax 45.00, toplam 45.00 (150 zaten tam sayı)

    # Bekleme Odası tetiklenir mi? 450 TL'lik bir alışveriş
    print("Bekleme Odası'na girer mi?", should_enter_waiting_room(Decimal("450.00"), settings))
