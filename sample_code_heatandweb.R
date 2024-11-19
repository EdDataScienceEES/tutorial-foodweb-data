# Visualising Food Webs on R
# Your name
# DD/MM/YYYY
# -------------------------------------

# 1.	Download data from cheddar

# Install arequired packages (omit if you already have them installed)
install.packages("cheddar") # data and functions for analysing/visualising food web data
install.packages("tidyverse") # includes data wrangling tools such as dplyr, tidyr
install.packages("ggplot2") # a useful graphic display tool
install.packages("igraph") # helps visualise food web network
install.packages("ggraph") # an extension of ggplot2, creates food web heat map

# Load required libraries
library(cheddar)
library(tidyverse) 
library(ggplot2)
library(igraph) 
library(ggraph)

# Obtain the BroadstoneStream dataset from cheddar and save the useful data frames as objects
data("BroadstoneStream")
node_properties <- NPS(BroadstoneStream) # Extract node properties (species data)
trophic_links <- TLPS(BroadstoneStream) # Extract trophic links (prey-predator interactions)
properties <- BroadstoneStream[["properties"]] # Extract properties (unit key)

# ALTERNATIVE: To directly access data without cheddar, instead of ("BroadstoneStream"), use the below code:
node_properties <- read.csv("nodes.csv")   # Extract node properties (species data)
trophic_links <- read.csv("trophic.links.csv")  # Extract trophic links (prey-predator interactions)
properties <- read.csv("properties.csv")  # Extract properties (unit key)

# Examine dataproperties# Examine data structure of node_properties and trophic_links
str(properties)
str(node_properties)
str(trophic_links)

# -------------------------------------

# 2.	Subset, extract and modify data using dplyr 

# Let's view what species do we have exactly!
unique(node_properties$node) 
# There are some producers and bacteria here! I would assume they are resources.
# See if they are in resources
unique(trophic_links$resource)

# They don't seem to be! If we run another line to find differences...
nodes_not_in_resources <- setdiff(unique(node_properties$node), unique(trophic_links$resource))
resources_not_in_nodes <- setdiff(unique(trophic_links$resource), unique(node_properties$node))
# And display the result...
list(Nodes_Not_in_Resources = nodes_not_in_resources,
  Resources_Not_in_Nodes = resources_not_in_nodes)

# Calculate biomass (M * N) for prey and keep only mass for predators
node_properties <- node_properties %>%
  mutate(
    Prey_Biomass = M * N,  # Prey biomass includes mass and density
    Predator_Mass = M      # Predator biomass is just the mass
  ) %>%
  select(node, Prey_Biomass, Predator_Mass)  # Keep only necessary columns

# Joining trophic_links with node_properties
trophic_links <- trophic_links %>%
  # Add prey biomass by joining on 'resource' (prey nodes)
  left_join(node_properties %>% select(node, Prey_Biomass), by = c("resource" = "node")) %>%
  # Add predator mass by joining on 'consumer' (predator nodes)
  left_join(node_properties %>% select(node, Predator_Mass), by = c("consumer" = "node")) %>%

# Calculate and normalise interaction strength
  trophic_links <- trophic_links %>%
  group_by(consumer) %>%  # Group by each predator (consumer)
  mutate(
    # Interaction strength using prey biomass and predator mass
    Interaction_Strength = Prey_Biomass / Predator_Mass,  
    # Normalize within each consumer (predator) group
    Normalized_Strength = Interaction_Strength / sum(Interaction_Strength, na.rm = TRUE)
  ) %>%
  ungroup()  # Ungroup after calculations to avoid accidental grouping later




# View the updated trophic links with interaction strengths
print(trophic_links)

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
