// Bonus Engine — Single Source of Truth für alle Bonus-Berechnungen.
// Pure ES-Modul, keine DOM-Abhängigkeiten. Wird sowohl im Browser (via
// <script type="module">) als auch in Deno Edge Functions und Node-Tests
// identisch verwendet. Formeln 1:1 extrahiert aus farm_bonussystem_komplett.html.

export const DEFAULTS = Object.freeze({
  // Tier-Staffelung (Raten in Prozent, werden intern durch 100 geteilt)
  tier1Rate: 8,   // 0 – 100k
  tier2Rate: 12,  // 100k – 500k
  tier3Rate: 15,  // 500k – 2M
  tier4Rate: 20,  // 2M – ebitCap
  // Tier-Grenzen in NAD (fix, nicht konfigurierbar)
  tier1Limit: 100000,
  tier2Limit: 500000,
  tier3Limit: 2000000,
  // EBIT-Cap in Millionen NAD (wird intern ×1e6 gerechnet)
  ebitCap: 4,
  // Gewichtung EBIT-Säule vs. Produktivitäts-Säule (Prozent)
  ebitWeight: 70,
  // Produktivitätsindex-Schwellen
  prodThresholdCritical: 15,
  prodThresholdOk: 20,
  prodThresholdGood: 25,
  // Produktivitätsindex-Faktoren
  prodFactorCritical: 0,
  prodFactorOk: 1.0,
  prodFactorGood: 1.5,
  prodFactorExcellent: 2.0,
});

/**
 * Progressive EBIT-Bonus-Staffelung.
 *
 * @param {number} ebit  EBIT in NAD (kann negativ sein)
 * @param {object} params  { tier1Rate, tier2Rate, tier3Rate, tier4Rate, ebitCap }
 *                         Raten in Prozent (z.B. 8 für 8%), ebitCap in Millionen NAD.
 * @returns {{ total: number, breakdown: Array }}
 */
export function calculateEbitBonus(ebit, params = DEFAULTS) {
  const tier1Rate = params.tier1Rate / 100;
  const tier2Rate = params.tier2Rate / 100;
  const tier3Rate = params.tier3Rate / 100;
  const tier4Rate = params.tier4Rate / 100;
  const ebitCapNad = params.ebitCap * 1000000;

  const cappedEbit = Math.min(ebit, ebitCapNad);
  let totalBonus = 0;
  const breakdown = [];

  // Stufe 1: 0 – 100k
  if (cappedEbit > 0) {
    const amount = Math.min(cappedEbit, DEFAULTS.tier1Limit);
    const bonus = amount * tier1Rate;
    totalBonus += bonus;
    breakdown.push({
      stufe: 'Stufe 1 (0-100k)',
      betrag: amount,
      rate: tier1Rate * 100,
      bonus,
    });
  }

  // Stufe 2: 100k – 500k
  if (cappedEbit > DEFAULTS.tier1Limit) {
    const amount = Math.min(
      cappedEbit - DEFAULTS.tier1Limit,
      DEFAULTS.tier2Limit - DEFAULTS.tier1Limit,
    );
    const bonus = amount * tier2Rate;
    totalBonus += bonus;
    breakdown.push({
      stufe: 'Stufe 2 (100k-500k)',
      betrag: amount,
      rate: tier2Rate * 100,
      bonus,
    });
  }

  // Stufe 3: 500k – 2M
  if (cappedEbit > DEFAULTS.tier2Limit) {
    const amount = Math.min(
      cappedEbit - DEFAULTS.tier2Limit,
      DEFAULTS.tier3Limit - DEFAULTS.tier2Limit,
    );
    const bonus = amount * tier3Rate;
    totalBonus += bonus;
    breakdown.push({
      stufe: 'Stufe 3 (500k-2M)',
      betrag: amount,
      rate: tier3Rate * 100,
      bonus,
    });
  }

  // Stufe 4: 2M – ebitCap
  if (cappedEbit > DEFAULTS.tier3Limit) {
    const amount = cappedEbit - DEFAULTS.tier3Limit;
    const bonus = amount * tier4Rate;
    totalBonus += bonus;
    breakdown.push({
      stufe: 'Stufe 4 (2M+)',
      betrag: amount,
      rate: tier4Rate * 100,
      bonus,
    });
  }

  return { total: totalBonus, breakdown };
}

/**
 * Produktivitätsindex — kg Schlachtgewicht pro 1.000 NAD Gesamtkosten.
 *
 * @param {number} slaughterKg  Gesamt verkauftes Schlachtgewicht in kg
 * @param {number} totalCost    Gesamtkosten in NAD
 * @returns {number}  Index (0 wenn Kosten ≤ 0)
 */
export function calculateProductivityIndex(slaughterKg, totalCost) {
  if (totalCost <= 0) return 0;
  return (slaughterKg / totalCost) * 1000;
}

/**
 * Produktivitäts-Faktor basierend auf Index.
 *
 * @param {number} index  Produktivitätsindex
 * @param {object} params  DEFAULTS oder Override
 * @returns {{ factor: number, rating: string }}
 */
export function productivityFactor(index, params = DEFAULTS) {
  if (index <= 0) {
    return { factor: 0, rating: 'Keine Kosten - nicht berechenbar - Faktor 0×' };
  }
  if (index < params.prodThresholdCritical) {
    return { factor: params.prodFactorCritical, rating: 'Kritisch - Faktor 0×' };
  }
  if (index <= params.prodThresholdOk) {
    return { factor: params.prodFactorOk, rating: 'Ok - Faktor 1,0×' };
  }
  if (index <= params.prodThresholdGood) {
    return { factor: params.prodFactorGood, rating: 'Gut - Faktor 1,5×' };
  }
  return { factor: params.prodFactorExcellent, rating: 'Exzellent - Faktor 2,0×' };
}

/**
 * EBIT-Pipeline-Kopf — aus Herdenparametern und sonstigen Einnahmen zum EBIT.
 *
 * @param {object} inputs  Herdenparameter + Revenue-Block + Costs
 * @returns {{ soldAnimals, totalSlaughterWeight, cattleRevenue, totalRevenue, totalCost, ebit }}
 */
export function calculateEbit({
  herdSize,
  slaughterWeight,
  salesRate, // als Prozent, z.B. 26 für 26%
  pricePerKg,
  huntingRevenue = 0,
  rentRevenue = 0,
  otherRevenue = 0,
  baseCosts,
}) {
  const soldAnimals = Math.round(herdSize * (salesRate / 100));
  const totalSlaughterWeight = soldAnimals * slaughterWeight;
  const cattleRevenue = totalSlaughterWeight * pricePerKg;
  const totalRevenue = cattleRevenue + huntingRevenue + rentRevenue + otherRevenue;
  const totalCost = baseCosts;
  const ebit = totalRevenue - totalCost;
  return {
    soldAnimals,
    totalSlaughterWeight,
    cattleRevenue,
    totalRevenue,
    totalCost,
    ebit,
  };
}

/**
 * Gesamtbonus — orchestriert EBIT-Bonus und Produktivitäts-Bonus.
 *
 * @param {object} args  { ebit, slaughterKg, totalCost, params }
 * @returns {{ ebitBonusRaw, ebitBonusWeighted, productivityIndex, prodFactor, prodRating, prodBonus, totalBonus, breakdown }}
 */
export function calculateBonus({ ebit, slaughterKg, totalCost, params = DEFAULTS }) {
  const ebitBonusResult = calculateEbitBonus(ebit, params);
  const ebitBonusRaw = ebitBonusResult.total;

  const ebitWeight = params.ebitWeight / 100;
  const prodWeight = 1 - ebitWeight;

  const ebitBonusWeighted = ebitBonusRaw * ebitWeight;

  const productivityIndex = calculateProductivityIndex(slaughterKg, totalCost);
  const { factor: prodFactor, rating: prodRating } = productivityFactor(productivityIndex, params);

  const prodBonusBase = ebitBonusRaw * prodWeight;
  const prodBonus = prodBonusBase * prodFactor;

  const totalBonus = ebitBonusWeighted + prodBonus;

  return {
    ebitBonusRaw,
    ebitBonusWeighted,
    productivityIndex,
    prodFactor,
    prodRating,
    prodBonus,
    totalBonus,
    breakdown: ebitBonusResult.breakdown,
  };
}
