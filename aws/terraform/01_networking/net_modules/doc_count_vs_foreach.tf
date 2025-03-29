/*
TERRAFORM COUNT VS FOR_EACH COMPARISON

LIMITATIONS OF COUNT:

1. Index-based Identification
   - Resources are identified by numeric indices (0, 1, 2...)
   - If you remove an element from the middle of a list, all subsequent indices change
   - Example: Removing subnet[1] causes subnet[2] to become subnet[1], subnet[3] to become subnet[2], etc.
   - Result: Terraform will destroy and recreate resources unnecessarily

2. Resource Dependency Problems
   - When indices change, all dependent resources must be updated
   - Can cause cascading changes throughout your infrastructure

3. List Order Sensitivity
   - Changing the order of elements in a list causes resource recreation
   - No stable identifiers to track resources across updates

4. Limited Metadata
   - Difficult to attach meaningful metadata to each resource
   - Can't easily represent complex relationships

ADVANTAGES OF FOR_EACH:

1. Key-based Identification
   - Resources are identified by keys that remain stable
   - Adding/removing elements doesn't affect other resources
   - Example: Removing subnet["app1"] doesn't affect subnet["app2"]

2. Resource Stability
   - Resources maintain their identity across updates
   - Less chance of accidental destruction/recreation

3. Explicit Resource Relationships
   - Key relationships are explicit and declarative
   - Better representation of resource dependencies

4. Rich Metadata Support
   - Can use complex objects as values in the map/set
   - Each resource can have associated metadata

AWS SPECIFIC CONSIDERATIONS:

1. Resource Recreation Costs
   - AWS often charges for resource creation/deletion
   - Unnecessary recreation with count can lead to additional costs

2. Infrastructure Stability
   - AWS resources often form complex dependency chains
   - Unexpected changes can cause service disruptions

3. State Management
   - AWS environments often have large state files
   - For_each provides better state organization

BEST PRACTICES:

1. Use for_each for most resource collections
2. Reserve count for simple numeric scaling scenarios
3. When converting from count to for_each, carefully plan state migrations
4. Use for_each when resources have logical identifiers
*/
