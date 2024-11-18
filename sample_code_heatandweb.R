# Load required libraries
library(tidyverse)
library(igraph)
library(ggraph)
library(cheddar)

# Step 1: Load and process Cheddar data
data("BroadstoneStream")  # Example dataset

# Extract node properties (species data)
node_properties <- NPS(BroadstoneStream) %>%
  mutate(Biomass = M * N) %>%  # Calculate biomass
  select(node, Biomass)  # Keep only necessary columns

# Extract trophic links (prey-predator interactions)
trophic_links <- TLPS(BroadstoneStream)

# Step 2: Join trophic links with prey and predator biomass
# Add prey biomass
trophic_links <- trophic_links %>%
  left_join(node_properties, by = c("resource" = "node")) %>%
  rename(Prey_Biomass = Biomass)  # Rename biomass for prey

# Add predator biomass
trophic_links <- trophic_links %>%
  left_join(node_properties, by = c("consumer" = "node")) %>%
  rename(Predator_Biomass = Biomass)  # Rename biomass for predator

# Step 3: Calculate interaction strength and normalize
trophic_efficiency <- 0.1  # Example trophic efficiency
trophic_links <- trophic_links %>%
  mutate(Interaction_Strength = trophic_efficiency * Prey_Biomass) %>%
  group_by(consumer) %>%
  mutate(Normalized_Strength = Interaction_Strength / sum(Interaction_Strength, na.rm = TRUE)) %>%
  ungroup()

# Step 4: Plot Heatmap
heatmap_plot <- ggplot(trophic_links, aes(x = consumer, y = resource, fill = Normalized_Strength)) +
  geom_tile() +
  scale_fill_gradient(low = "white", high = "red") +
  theme_minimal() +
  labs(title = "Food Web Heatmap of Interaction Strength",
       x = "Predator", y = "Prey") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))  # Rotate labels

# Print the heatmap
print(heatmap_plot)

# Step 5: Create Food Web Network Visualization
# Convert trophic_links to an igraph object
food_web_graph <- graph_from_data_frame(trophic_links, directed = TRUE)

# Use ggraph to visualize the food web
food_web_plot <- ggraph(food_web_graph, layout = 'fr') +  # Fruchterman-Reingold layout
  geom_edge_link(aes(alpha = Normalized_Strength), color = "blue") +  # Edges scaled by strength
  geom_node_point(color = "red", size = 5) +  # Nodes as circles
  geom_node_text(aes(label = name), repel = TRUE, size = 4) +  # Node labels
  theme_void() +
  labs(title = "Food Web Network Visualization",
       subtitle = "Predator-Prey Interactions")

# Print the food web plot
print(food_web_plot)
