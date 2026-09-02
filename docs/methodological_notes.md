# Methodological notes

## Study framing

This project examines observed relationships among price, quantity sold, revenue, location, festivals, weather, and time. It is designed as a transparent empirical workflow for an Information Systems research portfolio.

## Unit of analysis

The primary unit is a city-day operating record. The dataset contains 365 daily observations distributed across Hamilton, London, Toronto, and Waterloo.

## Outcomes and contextual variables

- Demand outcome: quantity sold
- Business outcome: daily revenue, calculated as price multiplied by quantity sold
- Focal predictor: posted price
- Context: city, festival status, weather, weekday/weekend, and season
- Market descriptors: city-level demographic indicators

## What the models identify

The log-linear and quadratic specifications describe conditional associations in the observed data. They are useful for pattern detection, model comparison, and decision support. They do not identify the causal effect of changing price.

## Threats to validity

1. **Endogenous pricing.** Managers may set price using information about expected demand.
2. **Omitted variables.** Product mix, inventory, competition, promotion, and local events may affect both price and sales.
3. **Small contextual samples.** Subgroup estimates can be unstable after dividing 365 observations across cities, seasons, and festival states.
4. **Functional-form dependence.** Estimated optima differ between log-linear and quadratic demand specifications.
5. **External validity.** The educational case is not representative of all food-service firms or digital platforms.

## Robustness roadmap

- Compare coefficient stability across specifications and leave-one-city-out analyses.
- Report uncertainty intervals for elasticity and estimated optimal prices.
- Use time-aware validation to avoid leakage across neighboring dates.
- Examine overlap in the observed price distribution within every context.
- Conduct sensitivity analysis for influential observations and alternative seasonal definitions.

## Causal extension

A future study could define price or promotional exposure as a treatment and estimate heterogeneous effects under a stronger design. Credible options include:

- randomized price experiments;
- a natural experiment or policy discontinuity;
- inverse-probability weighting with pre-treatment covariates;
- augmented inverse-probability weighting or double machine learning;
- clustered uncertainty estimates for repeated observations within operating units.

Any causal extension would need explicit timing, positivity, consistency, no-interference, and conditional-exchangeability assumptions. The current project intentionally stops short of those claims.

## Human-centered decision support

Model outputs should inform, not automate, pricing decisions. A human decision-maker should review uncertainty, operational constraints, customer fairness, and the potential distributional consequences of context-specific prices.
