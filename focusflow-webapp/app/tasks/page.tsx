'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { useSyncAuth, useOnlineStatus } from '@/hooks';
import AppHeader from '@/components/layout/AppHeader';
import { useTasks } from '@/hooks/supabase/useTasks';
import TaskForm from '@/components/tasks/TaskForm';
import TaskItem from '@/components/tasks/TaskItem';
import type { Task } from '@/types';
import { Plus, Filter } from 'lucide-react';
import { useTasksStore } from '@/stores/useTasksStore';

export default function TasksPage() {
  const { user, loading } = useAuth();
  const router = useRouter();
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingTask, setEditingTask] = useState<Task | null>(null);
  
  // Sync auth state with stores
  useSyncAuth();
  useOnlineStatus();
  
  // Fetch tasks
  const userId = user?.id;
  const { 
    tasks, 
    isLoading: tasksLoading, 
    addTask, 
    updateTask, 
    deleteTask,
    isAdding,
    isUpdating,
    isDeleting,
  } = useTasks(userId);
  
  // Get filter from store and compute filtered tasks
  const { filter, setFilter, getFilteredTasks } = useTasksStore();
  const filteredTasks = getFilteredTasks();
  
  useEffect(() => {
    if (!loading && !user) {
      router.push('/signin');
    }
  }, [user, loading, router]);

  const handleCreateTask = async (taskData: Omit<Task, 'id' | 'createdAt'>) => {
    try {
      await addTask(taskData);
      setIsFormOpen(false);
    } catch (error) {
      console.error('Failed to create task:', error);
      alert('Failed to create task. Please try again.');
    }
  };

  const handleUpdateTask = async (taskData: Omit<Task, 'id' | 'createdAt'>) => {
    if (!editingTask) return;
    
    try {
      await updateTask({ id: editingTask.id, updates: taskData });
      setEditingTask(null);
      setIsFormOpen(false);
    } catch (error) {
      console.error('Failed to update task:', error);
      alert('Failed to update task. Please try again.');
    }
  };

  const handleDeleteTask = async (id: string) => {
    try {
      await deleteTask(id);
    } catch (error) {
      console.error('Failed to delete task:', error);
      alert('Failed to delete task. Please try again.');
    }
  };

  const handleEditTask = (task: Task) => {
    setEditingTask(task);
    setIsFormOpen(true);
  };

  const handleCloseForm = () => {
    setIsFormOpen(false);
    setEditingTask(null);
  };

  const handleNewTask = () => {
    setEditingTask(null);
    setIsFormOpen(true);
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-[var(--foreground-muted)]">Loading...</div>
      </div>
    );
  }

  if (!user) {
    return null; // Will redirect
  }

  return (
    <div className="min-h-screen flex flex-col bg-[var(--background)]">
      <AppHeader />
      <main className="flex-1 container-wide px-4 md:px-6 lg:px-8 py-8 md:py-12">
        <div className="max-w-4xl mx-auto space-y-8">
          {/* Page Header */}
          <div className="flex items-center justify-between flex-wrap gap-4">
            <div className="space-y-2">
              <h1 className="text-3xl md:text-4xl font-bold">Tasks</h1>
              <p className="text-[var(--foreground-muted)]">
                Manage your tasks and stay organized
              </p>
            </div>
            <button 
              onClick={handleNewTask}
              className="btn btn-accent"
            >
              <Plus className="w-4 h-4" />
              New Task
            </button>
          </div>

          {/* Filters */}
          {tasks.length > 0 && (
            <div className="flex items-center gap-2 flex-wrap">
              <Filter className="w-4 h-4 text-[var(--foreground-muted)]" />
              <button
                onClick={() => setFilter('all')}
                className={`px-4 py-2 rounded-xl text-sm font-medium transition-all ${
                  filter === 'all'
                    ? 'bg-[var(--accent-primary)] text-white'
                    : 'bg-[var(--background-elevated)] text-[var(--foreground-muted)] hover:text-[var(--foreground)]'
                }`}
              >
                All
              </button>
              <button
                onClick={() => setFilter('active')}
                className={`px-4 py-2 rounded-xl text-sm font-medium transition-all ${
                  filter === 'active'
                    ? 'bg-[var(--accent-primary)] text-white'
                    : 'bg-[var(--background-elevated)] text-[var(--foreground-muted)] hover:text-[var(--foreground)]'
                }`}
              >
                Active
              </button>
              <button
                onClick={() => setFilter('today')}
                className={`px-4 py-2 rounded-xl text-sm font-medium transition-all ${
                  filter === 'today'
                    ? 'bg-[var(--accent-primary)] text-white'
                    : 'bg-[var(--background-elevated)] text-[var(--foreground-muted)] hover:text-[var(--foreground)]'
                }`}
              >
                Today
              </button>
            </div>
          )}

          {/* Tasks List */}
          <div className="card p-6">
            {tasksLoading ? (
              <div className="text-center py-12 text-[var(--foreground-muted)]">
                Loading tasks...
              </div>
            ) : filteredTasks.length === 0 ? (
              <div className="text-center py-12 space-y-4">
                <p className="text-[var(--foreground-muted)]">
                  {tasks.length === 0 
                    ? 'No tasks yet. Create your first task to get started!'
                    : 'No tasks match the current filter.'}
                </p>
                {tasks.length === 0 && (
                  <button 
                    onClick={handleNewTask}
                    className="btn btn-accent"
                  >
                    <Plus className="w-4 h-4" />
                    Create Task
                  </button>
                )}
              </div>
            ) : (
              <div className="space-y-3">
                {filteredTasks.map((task) => (
                  <TaskItem
                    key={task.id}
                    task={task}
                    onEdit={handleEditTask}
                    onDelete={handleDeleteTask}
                    isDeleting={isDeleting}
                  />
                ))}
              </div>
            )}
          </div>
        </div>
      </main>

      {/* Task Form Modal */}
      <TaskForm
        task={editingTask}
        isOpen={isFormOpen}
        onClose={handleCloseForm}
        onSubmit={editingTask ? handleUpdateTask : handleCreateTask}
        isSubmitting={isAdding || isUpdating}
      />
    </div>
  );
}

