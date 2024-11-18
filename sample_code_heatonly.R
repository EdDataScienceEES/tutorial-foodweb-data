# Load necessary libraries
install.packages("tidyverse")  # Uncomment if not installed
install.packages("cheddar")    # Uncomment if not installed
library(tidyverse)
library(cheddar)

# Step 1: Load and explore the data from cheddar
data("BroadstoneStream")  # Example dataset

# Extract node properties (e.g., body mass, abundance)
node_properties <- NPS(BroadstoneStream)

# Extract trophic links (prey-predator interactions)
trophic_links <- TLPS(BroadstoneStream)

# Step 2: Calculate biomass for each species (Body Mass * Abundance)
node_properties <- node_properties %>%
  mutate(Biomass = M * N) %>%
  select(node, M, N, Biomass)

# Step 3: Join biomass with trophic links to associate prey and predator biomass
trophic_links <- trophic_links %>%
  left_join(node_properties, by = c("resource" = "node")) %>%
  rename(Prey_Biomass = Biomass) %>%
  left_join(node_properties, by = c("consumer" = "node")) %>%
  rename(Predator_Biomass = Biomass)

# Step 4: Calculate interaction strength using a trophic efficiency (e.g., 0.1)
trophic_efficiency <- 0.1
trophic_links <- trophic_links %>%
  mutate(Interaction_Strength = trophic_efficiency * Prey_Biomass)

# Step 5: Normalize interaction strength by predator
trophic_links <- trophic_links %>%
  group_by(consumer) %>%
  mutate(Normalized_Strength = Interaction_Strength / sum(Interaction_Strength, na.rm = TRUE)) %>%
  ungroup()

# Step 6: Remove duplicates (if any) and keep in long format
trophic_links <- trophic_links %>%
  distinct(resource, consumer, .keep_all = TRUE)  # Remove duplicate interactions

# Step 7: Create a heatmap using ggplot2 (long format)
ggplot(trophic_links, aes(x = consumer, y = resource, fill = Normalized_Strength)) +
  geom_tile() +
  scale_fill_gradient(low = "white", high = "red") +
  theme_minimal() +
  labs(title = "Food Web Interaction Strengths",
       x = "Predator", y = "Prey") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))  # Rotate x-axis labels for readability

