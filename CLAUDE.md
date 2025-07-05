View Structure Rules
Replace HTML elements with React Native components:

<div> → <View>
<span>, <p>, <h1>-<h6> → <Text>
<button> → <TouchableOpacity> or <Pressable>
<input> → <TextInput>
<img> → <Image>
<ul>/<ol> → <FlatList> or <ScrollView>

No direct DOM manipulation:

Remove document.getElementById(), querySelector(), etc.
Use React state and refs instead

Component Architecture Rules
1. Functional Components with Hooks
javascriptimport React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';

const MyComponent = () => {
  const [state, setState] = useState(initialValue);
  
  return (
    <View style={styles.container}>
      <Text>Content</Text>
    </View>
  );
};
2. Component Organization

One component per file
Use PascalCase for component names
Keep components small and focused (single responsibility)
Extract reusable UI elements into separate components

3. Props and State Management

Pass data down through props
Lift state up to parent components when needed
Use Context API for global state
Consider Redux for complex state management

Styling Rules
1. StyleSheet API
javascriptconst styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
2. Flexbox Layout

Default layout is flexbox
Use flexDirection: 'column' (default) or 'row'
Replace CSS Grid with nested Views and Flexbox
Use flex: 1 for full available space

3. Responsive Design

Use Dimensions API for screen measurements
Percentage-based widths/heights
Consider different screen densities

Navigation Rules
1. Screen-based Navigation

Install React Navigation library
Replace HTML routing with Stack, Tab, or Drawer navigators
Each "page" becomes a separate screen component

2. Navigation Structure
javascriptimport { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';

const Stack = createStackNavigator();

function App() {
  return (
    <NavigationContainer>
      <Stack.Navigator>
        <Stack.Screen name="Home" component={HomeScreen} />
        <Stack.Screen name="Details" component={DetailsScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
Event Handling Rules
1. Touch Events

Replace onClick with onPress
Use TouchableOpacity for buttons with feedback
Use Pressable for advanced touch interactions

2. Form Handling

Replace form submissions with state updates
Use onChangeText for TextInput
Validate inputs in real-time

Data Flow Rules
1. No Direct API Calls in Components

Create separate service files for API calls
Use useEffect for data fetching
Handle loading and error states

2. State Updates

Always use state setters, never mutate state directly
Use functional updates for complex state
Consider useReducer for complex state logic

Performance Rules
1. List Rendering

Use FlatList or SectionList for large lists
Implement keyExtractor and renderItem
Use getItemLayout for fixed-height items

2. Image Optimization

Use appropriate image formats
Implement lazy loading for large images
Cache images when possible

File Structure Rules
src/
├── components/
│   ├── common/
│   └── specific/
├── screens/
├── services/
├── utils/
├── styles/
└── navigation/
Key Differences to Remember

No HTML/CSS: Everything is JavaScript components and StyleSheet
Mobile-First: Design for touch interactions and mobile UX patterns
Platform Differences: Some features work differently on Android vs iOS
Performance: Mobile apps need careful performance optimization
Native Modules: Some features require native Android/iOS code
