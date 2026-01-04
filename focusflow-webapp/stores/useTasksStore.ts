import { create } from 'zustand';
import type { Task } from '@/types';

interface TasksState {
  tasks: Task[];
  selectedTaskId: string | null;
  viewMode: 'list' | 'kanban' | 'calendar';
  filter: 'all' | 'active' | 'completed' | 'today';
  isLoading: boolean;
  
  // Actions
  setTasks: (tasks: Task[]) => void;
  setLoading: (loading: boolean) => void;
  addTask: (task: Task) => void;
  updateTask: (id: string, updates: Partial<Task>) => void;
  deleteTask: (id: string) => void;
  setSelectedTaskId: (id: string | null) => void;
  setViewMode: (mode: 'list' | 'kanban' | 'calendar') => void;
  setFilter: (filter: 'all' | 'active' | 'completed' | 'today') => void;
  
  // Computed getters
  getFilteredTasks: () => Task[];
  getTasksByDate: () => Record<string, Task[]>;
}

export const useTasksStore = create<TasksState>((set, get) => ({
  tasks: [],
  selectedTaskId: null,
  viewMode: 'list',
  filter: 'all',
  isLoading: false,
  
  setTasks: (tasks) => set({ tasks }),
  setLoading: (loading) => set({ isLoading: loading }),
  
  addTask: (task) => set((state) => ({
    tasks: [...state.tasks, task].sort((a, b) => a.sortIndex - b.sortIndex),
  })),
  
  updateTask: (id, updates) => set((state) => ({
    tasks: state.tasks.map((task) =>
      task.id === id ? { ...task, ...updates } : task
    ),
  })),
  
  deleteTask: (id) => set((state) => ({
    tasks: state.tasks.filter((task) => task.id !== id),
    selectedTaskId: state.selectedTaskId === id ? null : state.selectedTaskId,
  })),
  
  setSelectedTaskId: (id) => set({ selectedTaskId: id }),
  setViewMode: (mode) => set({ viewMode: mode }),
  setFilter: (filter) => set({ filter }),
  
  getFilteredTasks: () => {
    const { tasks, filter } = get();
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayStr = today.toISOString().split('T')[0];
    
    switch (filter) {
      case 'today':
        return tasks.filter((task) => {
          if (!task.reminderDate) return false;
          const taskDate = new Date(task.reminderDate);
          taskDate.setHours(0, 0, 0, 0);
          const taskDateStr = taskDate.toISOString().split('T')[0];
          return taskDateStr === todayStr;
        });
      case 'active':
        return tasks.filter((task) => {
          // Tasks without reminder dates or future dates
          if (!task.reminderDate) return true;
          const taskDate = new Date(task.reminderDate);
          taskDate.setHours(0, 0, 0, 0);
          return taskDate >= today;
        });
      case 'completed':
        // TODO: Implement when we have completion tracking
        return [];
      default:
        return tasks;
    }
  },
  
  getTasksByDate: () => {
    const filteredTasks = get().getFilteredTasks();
    const grouped: Record<string, Task[]> = {};
    
    filteredTasks.forEach((task) => {
      const dateKey = task.reminderDate
        ? new Date(task.reminderDate).toISOString().split('T')[0]
        : 'no-date';
      
      if (!grouped[dateKey]) {
        grouped[dateKey] = [];
      }
      grouped[dateKey].push(task);
    });
    
    return grouped;
  },
}));

